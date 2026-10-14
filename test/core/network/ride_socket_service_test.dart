import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/models/token_payload.dart';
import 'package:rapidoo/core/network/ride_socket_service.dart';
import 'package:rapidoo/core/session/auth_session.dart';
import 'package:rapidoo/core/storage/secure_storage_helper.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A socket whose handshake the test settles by hand.
class _FakeChannel implements WebSocketChannel {
  _FakeChannel(this.accessToken);

  /// The token the service opened it with.
  final String accessToken;

  final _ready = Completer<void>();
  final _incoming = StreamController<dynamic>();
  final _sink = _FakeSink();
  int? _closeCode;

  /// The server accepts the handshake.
  void accept() => _ready.complete();

  /// The handshake fails with [error].
  void refuse(Object error) => _ready.completeError(error);

  /// The server closes the open socket with [code].
  void serverClose(int? code) {
    _closeCode = code;
    _incoming.close();
  }

  /// The frames the service sent upstream.
  List<Object?> get sent => _sink.sent;

  /// The close code the service closed the socket with, if it did.
  int? get closedWith => _sink.closedWith;

  @override
  Future<void> get ready => _ready.future;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  int? get closeCode => _closeCode;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSink implements WebSocketSink {
  final sent = <Object?>[];
  int? closedWith;

  @override
  void add(Object? data) => sent.add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closedWith = closeCode;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A JWT named [id] that expires after [expiresIn]; only `exp` is read.
String _jwt(String id, {Duration expiresIn = const Duration(hours: 1)}) {
  final exp = DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  String segment(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${segment({'alg': 'HS256'})}.${segment({'jti': id, 'exp': exp})}.sig';
}

/// What the channel reports when the server answers the upgrade with a 401.
WebSocketChannelException _unauthorized() => WebSocketChannelException.from(
      const WebSocketException('Connection was not upgraded to websocket', 401),
    );

/// What the channel reports when the server can't be reached.
WebSocketChannelException _unreachable() => WebSocketChannelException.from(
      const SocketException('Connection refused'),
    );

void main() {
  final defaultChannelFactory = RideSocketService.channelFactory;
  final defaultRefresh = RideSocketService.refreshAccessToken;
  final validToken = _jwt('valid');
  final refreshedToken = _jwt('refreshed');

  late List<_FakeChannel> channels;
  late int refreshCalls;

  Future<void> signIn(String accessToken) => AuthSession.setTokens(
        accessToken: accessToken,
        refreshToken: 'refresh-token',
      );

  setUpAll(() {
    SecureStorageHelper.init();
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    await signIn(validToken);
    channels = [];
    refreshCalls = 0;
    RideSocketService.channelFactory = (uri, accessToken) {
      final channel = _FakeChannel(accessToken);
      channels.add(channel);
      return channel;
    };
    RideSocketService.refreshAccessToken = () async {
      refreshCalls++;
      return refreshedToken;
    };
  });

  // Each test also disconnects at its end: a reconnect timer still pending
  // when a testWidgets body returns fails the test.
  tearDown(() {
    RideSocketService.disconnect();
    RideSocketService.channelFactory = defaultChannelFactory;
    RideSocketService.refreshAccessToken = defaultRefresh;
  });

  group('RideSocketService', () {
    testWidgets('reports connected, and sends, only once the handshake is done',
        (tester) async {
      unawaited(RideSocketService.connect(ActiveRole.driver));
      await tester.pump();

      expect(RideSocketService.status, RideSocketStatus.connecting);
      expect(channels.single.accessToken, validToken);
      expect(RideSocketService.send({'type': 'driver.location'}), isFalse);

      channels.single.accept();
      await tester.pump();

      expect(RideSocketService.status, RideSocketStatus.connected);
      expect(RideSocketService.send({'type': 'driver.location'}), isTrue);
      expect(channels.single.sent, [
        jsonEncode({'type': 'driver.location'}),
      ]);

      RideSocketService.disconnect();
      expect(channels.single.closedWith, 1000);
    });

    testWidgets('a failed handshake schedules one reconnect, 1 → 2 → 4 s apart',
        (tester) async {
      unawaited(RideSocketService.connect(ActiveRole.driver));
      await tester.pump();

      // With ±20 % jitter, the next attempt comes after 80 % of the step and
      // before 120 % of it.
      for (final step in const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
      ]) {
        final attempts = channels.length;
        channels.last.refuse(_unreachable());
        await tester.pump();
        expect(RideSocketService.status, RideSocketStatus.reconnecting);

        await tester.pump(step * 0.79);
        expect(channels, hasLength(attempts), reason: 'too early for $step');
        await tester.pump(step * 0.42);
        expect(channels, hasLength(attempts + 1), reason: 'one retry, $step');
      }

      // Nothing more is scheduled while that attempt is pending.
      await tester.pump(const Duration(minutes: 1));
      expect(channels, hasLength(4));
      expect(RideSocketService.status, RideSocketStatus.reconnecting);

      RideSocketService.disconnect();
    });

    testWidgets('a socket the server drops reconnects once, on the backoff',
        (tester) async {
      unawaited(RideSocketService.connect(ActiveRole.driver));
      await tester.pump();
      channels.single.accept();
      await tester.pump();

      channels.single.serverClose(4004);
      await tester.pump();

      expect(RideSocketService.status, RideSocketStatus.reconnecting);
      expect(RideSocketService.send({'type': 'driver.location'}), isFalse);
      await tester.pump(const Duration(milliseconds: 790));
      expect(channels, hasLength(1));
      await tester.pump(const Duration(milliseconds: 420));
      expect(channels, hasLength(2));

      RideSocketService.disconnect();
    });

    testWidgets(
        'disconnect() returns at once while a handshake is pending that '
        'later fails', (tester) async {
      // The real channel: its sink.close() would never complete here.
      final socket = Completer<WebSocket>();
      var attempts = 0;
      RideSocketService.channelFactory = (uri, accessToken) {
        attempts++;
        return IOWebSocketChannel(socket.future);
      };

      unawaited(RideSocketService.connect(ActiveRole.driver));
      await tester.pump();
      expect(RideSocketService.status, RideSocketStatus.connecting);

      RideSocketService.disconnect();
      expect(RideSocketService.status, RideSocketStatus.disconnected);

      socket.completeError(const SocketException('Connection timed out'));
      await tester.pump(const Duration(minutes: 1));

      expect(RideSocketService.status, RideSocketStatus.disconnected);
      expect(attempts, 1);
    });

    testWidgets(
        'a handshake 401 refreshes once and retries at once; '
        'a second 401 fails', (tester) async {
      unawaited(RideSocketService.connect(ActiveRole.driver));
      await tester.pump();

      channels.single.refuse(_unauthorized());
      await tester.pump();

      expect(refreshCalls, 1);
      expect(channels, hasLength(2), reason: 'retried with no backoff');
      expect(channels.last.accessToken, refreshedToken);

      channels.last.refuse(_unauthorized());
      await tester.pump();

      expect(RideSocketService.status, RideSocketStatus.failed);
      expect(refreshCalls, 1);
      await tester.pump(const Duration(minutes: 1));
      expect(channels, hasLength(2), reason: 'a second 401 stops retrying');

      // The next explicit connect() starts over.
      unawaited(RideSocketService.connect(ActiveRole.driver));
      await tester.pump();
      expect(channels, hasLength(3));
      expect(RideSocketService.status, RideSocketStatus.connecting);

      RideSocketService.disconnect();
    });

    testWidgets('disconnect() during the refresh before connecting never '
        'opens a socket', (tester) async {
      await signIn(_jwt('expiring', expiresIn: const Duration(seconds: 30)));
      final refresh = Completer<String>();
      RideSocketService.refreshAccessToken = () {
        refreshCalls++;
        return refresh.future;
      };

      unawaited(RideSocketService.connect(ActiveRole.driver));
      await tester.pump();
      expect(refreshCalls, 1);
      expect(channels, isEmpty);

      RideSocketService.disconnect();
      refresh.complete(refreshedToken);
      await tester.pump(const Duration(minutes: 1));

      expect(channels, isEmpty);
      expect(RideSocketService.status, RideSocketStatus.disconnected);
    });

    testWidgets('a token about to expire is refreshed before the handshake',
        (tester) async {
      await signIn(_jwt('expiring', expiresIn: const Duration(seconds: 30)));

      unawaited(RideSocketService.connect(ActiveRole.passenger));
      await tester.pump();

      expect(refreshCalls, 1);
      expect(channels.single.accessToken, refreshedToken);

      RideSocketService.disconnect();
    });

    testWidgets(
        'a refresh that fails for a network reason keeps the session and '
        'retries on the backoff', (tester) async {
      await signIn(_jwt('expired', expiresIn: const Duration(minutes: -5)));
      RideSocketService.refreshAccessToken = () async {
        refreshCalls++;
        throw const SocketException('Network is unreachable');
      };

      unawaited(RideSocketService.connect(ActiveRole.driver));
      await tester.pump();

      expect(refreshCalls, 1);
      expect(channels, isEmpty);
      expect(RideSocketService.status, RideSocketStatus.reconnecting);
      expect(AuthSession.accessToken, isNotNull);

      await tester.pump(const Duration(milliseconds: 1210));
      expect(refreshCalls, 2);

      RideSocketService.disconnect();
    });

    testWidgets('close 4001 refreshes the token and reconnects at once',
        (tester) async {
      unawaited(RideSocketService.connect(ActiveRole.driver));
      await tester.pump();
      channels.single.accept();
      await tester.pump();

      channels.single.serverClose(4001);
      await tester.pump();

      expect(refreshCalls, 1);
      expect(channels, hasLength(2));
      expect(channels.last.accessToken, refreshedToken);

      channels.last.accept();
      await tester.pump();
      expect(RideSocketService.status, RideSocketStatus.connected);

      RideSocketService.disconnect();
    });
  });
}
