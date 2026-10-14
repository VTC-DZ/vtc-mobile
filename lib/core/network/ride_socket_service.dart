import 'dart:async';
import 'dart:convert';
import 'dart:io' show WebSocket;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/web_socket_constants.dart';
import '../models/token_payload.dart';
import '../session/auth_session.dart';
import '../session/session_teardown.dart';
import 'dio_client.dart';
import 'driver_location_streamer.dart';
import 'ride_socket_policy.dart';
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
/// backoff, the connection status, and close-code handling. Incoming frames go
/// out unparsed on [frameStream]; [send] writes upstream envelopes.
///
/// [RideSocketStatus.connected] means the server has accepted the handshake.
/// Until then the status is `connecting` or `reconnecting` and [send] writes
/// nothing. Each failed attempt schedules exactly one new attempt, on the
/// [backoffDelay] ladder. The server checks the access token only at the
/// handshake, so a token about to expire is refreshed before connecting, and
/// a handshake refused with HTTP 401 is refreshed and retried once.
///
/// Every attempt gets a generation number. [connect] and [disconnect] bump it,
/// and every step after an `await` checks it, so an attempt that has been
/// overtaken never touches the current one.
///
/// Implemented as a static singleton to match [DioClient]; the access token is
/// read from [AuthSession].
///
/// See `swagger/epic-03-ride.md` §4 for the protocol.
final class RideSocketService {
  RideSocketService._();

  /// The open socket. Set only once the server has accepted the handshake.
  static WebSocketChannel? _channel;
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
  static int _generation = 0; // bumped by every attempt and every disconnect
  static int _failures = 0; // consecutive failed attempts; drives the backoff
  static bool _connecting = false; // an attempt is in flight
  static Timer? _reconnectTimer;
  static RideSocketStatus _status = RideSocketStatus.disconnected;

  /// Opens the socket for [uri] with [accessToken]. Tests replace it with a
  /// fake channel.
  @visibleForTesting
  static WebSocketChannel Function(Uri uri, String accessToken)
      channelFactory = _openChannel;

  /// Refreshes the access token. Tests replace it with a fake.
  @visibleForTesting
  static Future<String> Function() refreshAccessToken =
      DioClient.refreshAccessToken;

  /// Last-emitted [RideSocketStatus], for callers that need the current value
  /// without subscribing to [statusStream] (e.g. on startup).
  static RideSocketStatus get status => _status;

  /// The role the socket is open, opening or waiting to reconnect for, or
  /// `null` when disconnected.
  static ActiveRole? get activeRole => _activeRole;

  /// Connects to the socket endpoint for [role].
  ///
  /// Idempotent: a no-op while a socket for [role] is open or opening; a
  /// socket for the other role is closed first. Completes once the attempt
  /// has settled (open, refused, or waiting to retry), so a caller that
  /// doesn't need the socket yet calls it with `unawaited(...)`. Never throws:
  /// a missing token or an unknown role emits [RideSocketStatus.failed].
  static Future<void> connect(ActiveRole role) async {
    if (role == ActiveRole.unknown) {
      _log('connect refused: role unknown');
      _emit(RideSocketStatus.failed);
      return;
    }

    if (_activeRole == role && (_channel != null || _connecting)) {
      _log('connect skipped: already '
          '${_connecting ? 'connecting' : 'connected'}');
      return;
    }

    // Switching role → tear the previous connection down first.
    if (_activeRole != null && _activeRole != role) disconnect();

    await _open(role);
  }

  /// Closes the socket and stops reconnecting. Idempotent.
  ///
  /// Returns at once: it never waits for the close handshake, which never
  /// completes while the opening handshake is still pending. An attempt still
  /// in flight finds it has been overtaken and closes its own socket.
  static void disconnect() {
    _generation++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final channel = _channel;
    final sub = _socketSub;
    _channel = null;
    _socketSub = null;
    _activeRole = null;
    _connecting = false;
    _failures = 0;
    unawaited(sub?.cancel());
    unawaited(channel?.sink.close(WebSocketConstants.closeNormal));
    _emit(RideSocketStatus.disconnected);
    _log('disconnected (intentional)');
  }

  /// Tears down everything, including the stream controllers. Intended for app
  /// teardown only — the service is app-global, so this is rarely called.
  static Future<void> dispose() async {
    disconnect();
    await _statusController.close();
    await _frameController.close();
  }

  /// Sends an upstream envelope (e.g. `driver.location`) over the socket.
  ///
  /// Returns `false` without throwing unless the server has accepted the
  /// socket — callers (e.g. [DriverLocationStreamer]) then fall back to REST
  /// rather than treat it as an error. See `swagger/epic-03-ride.md` §4/§5 for
  /// the envelope shape and the set of upstream message types.
  static bool send(Map<String, dynamic> envelope) {
    final channel = _channel;
    if (channel == null) {
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

  // --- Connection attempts ---

  /// One attempt to open the socket for [role].
  ///
  /// [afterRejection] marks an attempt made right after the server refused
  /// the token (a handshake 401 or a close 4001): the token is refreshed
  /// first, and a second refusal in a row stops with
  /// [RideSocketStatus.failed], since a fresh token won't fix it (a role
  /// mismatch, say).
  static Future<void> _open(
    ActiveRole role, {
    bool afterRejection = false,
  }) async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _activeRole = role;
    _connecting = true;
    final gen = ++_generation;
    _emit(_failures == 0 && !afterRejection
        ? RideSocketStatus.connecting
        : RideSocketStatus.reconnecting);

    final current = AuthSession.accessToken;
    if (current == null) {
      _log('connect refused: no access token');
      _fail();
      return;
    }
    final token = afterRejection || tokenNeedsRefresh(current, DateTime.now())
        ? await _refresh()
        : current;
    if (gen != _generation) return; // disconnected or overtaken meanwhile
    if (token == null) {
      // The refresh failed for a network reason; try again on the backoff.
      _retryLater(role);
      return;
    }

    _log('connecting as $role ...');
    final WebSocketChannel channel;
    try {
      channel = channelFactory(_endpoint(role), token);
      await channel.ready;
    } catch (e) {
      if (gen != _generation) return;
      _log('handshake failed: $e');
      if (!isHandshakeUnauthorized(e)) {
        _retryLater(role);
      } else if (afterRejection) {
        _fail();
      } else {
        await _open(role, afterRejection: true);
      }
      return;
    }
    if (gen != _generation) {
      // Disconnected while the handshake was in flight: close what it opened.
      unawaited(channel.sink.close(WebSocketConstants.closeNormal));
      return;
    }

    _connecting = false;
    _failures = 0;
    _channel = channel;
    _socketSub = channel.stream.listen(
      _onData,
      // The done event that follows an error does the reconnecting.
      onError: (Object e) => _log('stream error: $e'),
      onDone: () => _onClosed(gen, role, channel),
    );
    _emit(RideSocketStatus.connected);
    _log('connected as $role');
  }

  /// Schedules the next attempt on the backoff ladder. Nothing else schedules
  /// one, so each failure gives exactly one reconnect.
  static void _retryLater(ActiveRole role) {
    _connecting = false;
    final delay = backoffDelay(_failures++);
    _emit(RideSocketStatus.reconnecting);
    _log('reconnecting in ${delay.inMilliseconds} ms ...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => unawaited(_open(role)));
  }

  /// Stops trying until the next explicit [connect].
  static void _fail() {
    _connecting = false;
    _failures = 0;
    _emit(RideSocketStatus.failed);
  }

  // --- Stream callbacks ---

  static void _onData(dynamic data) {
    if (data is! String || _frameController.isClosed) return;
    // Intercept system.token_expiring before broadcasting so we can refresh
    // proactively without dropping the connection (epic-03-ride.md §4).
    if (_isTokenExpiringFrame(data)) {
      unawaited(_handleTokenExpiring());
    }
    _frameController.add(data);
  }

  static bool _isTokenExpiringFrame(String frame) {
    try {
      final type =
          (jsonDecode(frame) as Map<String, dynamic>)['type'] as String?;
      return type == 'system.token_expiring';
    } catch (_) {
      return false;
    }
  }

  static void _onClosed(int gen, ActiveRole role, WebSocketChannel channel) {
    if (gen != _generation) return; // closed by disconnect(), or overtaken
    final code = channel.closeCode;
    _log('socket closed (code=$code)');
    _socketSub = null;
    _channel = null;

    switch (interpretCloseCode(code)) {
      case WebSocketCloseMeaning.normal:
        // Server-initiated normal close — honor it; do not reconnect.
        _emit(RideSocketStatus.disconnected);
      case WebSocketCloseMeaning.authRevoked:
        _emit(RideSocketStatus.failed);
        unawaited(_forceRelogin());
      case WebSocketCloseMeaning.tokenExpired:
        // The server refused the token: refresh it, then reconnect at once.
        unawaited(_open(role, afterRejection: true));
      case WebSocketCloseMeaning.rateLimited:
      case WebSocketCloseMeaning.serverShutdown:
      case WebSocketCloseMeaning.transient:
        _retryLater(role);
    }
  }

  // --- Token refresh / teardown helpers ---

  /// Called when the server sends `system.token_expiring` (~2 min warning).
  /// Refreshes via REST and sends the new token upstream so the socket stays
  /// alive without a disconnect/reconnect cycle.
  static Future<void> _handleTokenExpiring() async {
    final gen = _generation;
    final newToken = await _refresh();
    if (newToken == null || gen != _generation) return;
    send({'type': 'system.auth_refresh', 'payload': {'token': newToken}});
    _log('token refreshed proactively via system.token_expiring');
  }

  /// Refreshes via [DioClient.refreshAccessToken], which shares a single
  /// in-flight refresh with any REST-401-triggered refresh — calling our own
  /// separate `/api/auth/refresh` here would race it, and since the backend
  /// rotates refresh tokens on use, the loser of that race would fail with a
  /// 401 on the refresh endpoint itself and force a logout even though the
  /// other call already renewed the session.
  ///
  /// Returns `null` when the refresh fails. If the server rejected the session,
  /// [DioClient] has already ended it; any other failure (timeout, no network,
  /// 5xx) keeps it, and the caller tries again later. Without a refresh token
  /// there is no session to refresh, so that case still forces re-login.
  static Future<String?> _refresh() async {
    if (AuthSession.refreshToken == null) {
      await _forceRelogin();
      return null;
    }
    try {
      return await refreshAccessToken();
    } catch (e) {
      _log('token refresh failed: $e');
      return null;
    }
  }

  static Future<void> _forceRelogin() async {
    _log('auth revoked — clearing session and forcing re-login');
    await SessionTeardown.run();
  }

  static void _emit(RideSocketStatus status) {
    if (status == _status) return;
    _status = status;
    if (_statusController.isClosed) return;
    _statusController.add(status);
  }

  static Uri _endpoint(ActiveRole role) {
    final path = role == ActiveRole.driver
        ? WebSocketConstants.driverEndpoint
        : WebSocketConstants.passengerEndpoint;
    return Uri.parse('${wsBaseUrl()}$path');
  }

  /// Opens the socket with [accessToken] in the `Authorization` header of the
  /// upgrade request, which is where the server reads it.
  ///
  /// Gives up on the handshake after [WebSocketConstants.connectTimeout]. The
  /// timeout can't cancel `WebSocket.connect`, so a socket that still opens
  /// after it is closed here: left open, it would stay registered on the
  /// server and receive every event, with nothing reading it. (That is why
  /// this doesn't use `IOWebSocketChannel.connect`'s own `connectTimeout`.)
  static WebSocketChannel _openChannel(Uri uri, String accessToken) {
    final socket = WebSocket.connect(
      uri.toString(),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).then((ws) => ws..pingInterval = WebSocketConstants.pingInterval);
    return IOWebSocketChannel(
      socket.timeout(
        WebSocketConstants.connectTimeout,
        onTimeout: () {
          socket
              .then((ws) => ws.close(WebSocketConstants.closeNormal))
              .ignore();
          throw TimeoutException(
            'WebSocket handshake timed out',
            WebSocketConstants.connectTimeout,
          );
        },
      ),
    );
  }

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[RideSocket] $msg');
  }
}
