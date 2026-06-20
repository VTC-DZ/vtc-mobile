import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';

import '../constants/web_socket_constants.dart';
import '../models/token_payload.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
import '../session/auth_session.dart';
import 'ws_url.dart';

/// Coarse connection state for the ride socket. Mirrored to UI via
/// [WebSocketConnectionCubit].
enum RideSocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Raw WebSocket transport for the ride surfaces (`/ws/passenger`, `/ws/driver`).
///
/// Owns the connection lifecycle only: connect, disconnect, reconnect with
/// exponential backoff, connection status, and close-code interpretation. It
/// does NOT parse envelopes or send upstream messages yet — those hook into
/// [frameStream] / a future `send()` (see the marked seams).
///
/// Implemented as a static singleton to match [DioClient]; the active access
/// token and role are read from [AuthSession] / [ActiveRole].
///
/// See `swagger/epic-03-ride.md` §4 for the protocol.
final class RideSocketService {
  RideSocketService._();

  static IOWebSocketChannel? _channel;
  static StreamSubscription<dynamic>? _socketSub;

  // --- Hook points for future work ---
  static final StreamController<RideSocketStatus> _statusController =
      StreamController<RideSocketStatus>.broadcast();
  static final StreamController<String> _frameController =
      StreamController<String>.broadcast();

  /// Coarse connection state changes.
  static Stream<RideSocketStatus> get statusStream => _statusController.stream;

  /// Raw incoming text frames (full envelope JSON, unparsed). A future
  /// `EventRouter` will subscribe here, decode `type`/`payload`, and dispatch
  /// to feature cubits. Intentionally not parsed in this layer.
  static Stream<String> get frameStream => _frameController.stream;

  // --- Internal state ---
  static ActiveRole? _activeRole;
  static bool _intentionalClose = false; // distinguishes user-stop from errors
  static int _backoffIndex = 0;
  static Timer? _reconnectTimer;
  static bool _isConnecting = false; // guards connect() re-entrancy
  static RideSocketStatus _status = RideSocketStatus.disconnected;

  /// Last-emitted [RideSocketStatus], for callers that need the current value
  /// without subscribing to [statusStream] (e.g. on startup).
  static RideSocketStatus get status => _status;

  /// The role the socket is currently open for, or `null` when disconnected.
  static ActiveRole? get activeRole => _activeRole;

  /// Connects to the socket endpoint for [role].
  ///
  /// Idempotent: a no-op when already connecting/connected for the same role;
  /// if connected for a different role it disconnects first. Reads the access
  /// token fresh via [AuthSession]. A null token or unknown role emits
  /// [RideSocketStatus.failed] and returns without throwing.
  static Future<void> connect(ActiveRole role) async {
    if (role == ActiveRole.unknown) {
      _log('connect refused: role unknown');
      _emit(RideSocketStatus.failed);
      return;
    }

    // Already connecting/connected for the same role → nothing to do.
    if (_isConnecting || (_channel != null && _activeRole == role)) {
      _log('connect skipped: already ${_isConnecting ? 'connecting' : 'connected'}');
      return;
    }

    // Switching role → tear the previous connection down first.
    if (_channel != null && _activeRole != role) {
      await disconnect();
    }

    final token = _currentToken();
    if (token == null) {
      _log('connect refused: no access token');
      _emit(RideSocketStatus.failed);
      return;
    }

    _activeRole = role;
    _intentionalClose = false;
    _isConnecting = true;
    _emit(RideSocketStatus.connecting);
    _log('connecting as $role ...');

    final endpoint = role == ActiveRole.driver
        ? WebSocketConstants.driverEndpoint
        : WebSocketConstants.passengerEndpoint;
    final uri = Uri.parse('${wsBaseUrl()}$endpoint');

    _channel = _createChannel(uri, {'Authorization': 'Bearer $token'});
    _socketSub = _channel!.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
    );

    // The server validates the token before upgrading, so treating channel
    // creation as "connected" is safe and self-correcting — a rejected
    // handshake surfaces immediately via onDone/onError.
    _isConnecting = false;
    _backoffIndex = 0; // reset backoff on a successful (re)connect
    _emit(RideSocketStatus.connected);
    _log('connected as $role');
  }

  /// Disconnects and does NOT auto-reconnect. Idempotent.
  static Future<void> disconnect() async {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _socketSub?.cancel();
    _socketSub = null;
    await _channel?.sink.close(WebSocketConstants.closeNormal);
    _channel = null;
    _activeRole = null;
    _isConnecting = false;
    _backoffIndex = 0;
    _emit(RideSocketStatus.disconnected);
    _log('disconnected (intentional)');
  }

  /// Tears down everything, including the stream controllers. Intended for app
  /// teardown only — the service is app-global, so this is rarely called.
  static Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
    await _frameController.close();
  }

  /// Sends an upstream envelope (e.g. `driver.location`) over the socket.
  ///
  /// Returns `false` without throwing when there is no live connection —
  /// callers (e.g. [DriverLocationStreamer]) treat that as "nothing to do"
  /// rather than an error. See `swagger/epic-03-ride.md` §4/§5 for the
  /// envelope shape and the set of upstream message types.
  static bool send(Map<String, dynamic> envelope) {
    final channel = _channel;
    if (channel == null || _status != RideSocketStatus.connected) {
      _log('send skipped: not connected');
      return false;
    }
    try {
      channel.sink.add(jsonEncode(envelope));
      return true;
    } catch (e) {
      _log('send failed: $e');
      return false;
    }
  }

  // --- Stream callbacks ---

  static void _onData(dynamic data) {
    // Pass raw text frames straight through; binary/other types are ignored.
    if (data is String && !_frameController.isClosed) {
      _frameController.add(data);
    }
  }

  static void _onError(Object error, StackTrace stack) {
    _log('stream error: $error');
    _isConnecting = false;
    if (_intentionalClose) return;
    _scheduleReconnect();
  }

  static void _onDone() {
    final code = _channel?.closeCode;
    _log('socket closed (code=$code)');
    _isConnecting = false;

    // Drop the dead connection; reconnect arms a fresh one.
    _socketSub?.cancel();
    _socketSub = null;
    _channel = null;

    if (_intentionalClose) {
      _emit(RideSocketStatus.disconnected);
      return;
    }

    switch (interpretCloseCode(code)) {
      case WebSocketCloseMeaning.normal:
        // Server-initiated normal close — honor it; do not reconnect.
        _emit(RideSocketStatus.disconnected);
      case WebSocketCloseMeaning.authRevoked:
        _emit(RideSocketStatus.failed);
        _forceRelogin();
      case WebSocketCloseMeaning.tokenExpired:
        // TODO(auth-refresh): refresh via REST, then fresh connect(role)
        //   without dropping the link. For now reconnect with the current
        //   token; if it is still expired this cycles within the backoff cap.
        _scheduleReconnect();
      case WebSocketCloseMeaning.rateLimited:
      case WebSocketCloseMeaning.serverShutdown:
      case WebSocketCloseMeaning.transient:
        _scheduleReconnect();
    }
  }

  // --- Reconnect / teardown helpers ---

  static void _scheduleReconnect() {
    if (_intentionalClose) return;
    final role = _activeRole;
    if (role == null) return;

    const steps = WebSocketConstants.backoffSteps;
    final step = steps[_backoffIndex.clamp(0, steps.length - 1)];
    _backoffIndex = (_backoffIndex + 1).clamp(0, steps.length - 1);

    _emit(RideSocketStatus.reconnecting);
    _log('reconnecting in ${step.inSeconds}s ...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(step, () => connect(role));
  }

  static Future<void> _forceRelogin() async {
    _log('auth revoked — clearing session and forcing re-login');
    await AuthSession.clearSession();
    AppRouter.router.go(RouteNames.phone);
  }

  static void _emit(RideSocketStatus status) {
    _status = status;
    if (_statusController.isClosed) return;
    _statusController.add(status);
  }

  // --- Testability seams: small private indirections a future test pass can
  //     override without an API change (no DI container — matches [DioClient]). ---

  static IOWebSocketChannel _createChannel(
    Uri uri,
    Map<String, dynamic> headers,
  ) {
    return IOWebSocketChannel.connect(
      uri,
      headers: headers,
      pingInterval: WebSocketConstants.pingInterval,
    );
  }

  static String? _currentToken() => AuthSession.accessToken;

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[RideSocket] $msg');
  }
}
