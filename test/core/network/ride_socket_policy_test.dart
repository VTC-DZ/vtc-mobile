import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/constants/web_socket_constants.dart';
import 'package:rapidoo/core/network/ride_socket_policy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A [Random] whose `nextDouble()` always returns [value].
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

/// A JWT carrying [claims]; the header and signature are never checked.
String _jwt(Map<String, dynamic> claims) {
  String segment(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${segment({'alg': 'HS256'})}.${segment(claims)}.signature';
}

void main() {
  group('backoffDelay', () {
    test('climbs 1 → 2 → 4 → 8 → 16 s', () {
      final noJitter = _FixedRandom(0.5);
      expect(
        [for (var i = 0; i < 5; i++) backoffDelay(i, random: noJitter)],
        const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
          Duration(seconds: 8),
          Duration(seconds: 16),
        ],
      );
    });

    test('stays at 16 s past the last step', () {
      final noJitter = _FixedRandom(0.5);
      for (final failures in [5, 10, 100]) {
        expect(
          backoffDelay(failures, random: noJitter),
          const Duration(seconds: 16),
        );
      }
    });

    test('jitter moves a step by at most 20 % either way', () {
      expect(
        backoffDelay(0, random: _FixedRandom(0)),
        const Duration(milliseconds: 800),
      );
      expect(
        backoffDelay(2, random: _FixedRandom(0)),
        const Duration(milliseconds: 3200),
      );
      final top = backoffDelay(0, random: _FixedRandom(0.99));
      expect(top, greaterThan(const Duration(milliseconds: 1190)));
      expect(top, lessThan(const Duration(milliseconds: 1200)));

      final random = Random(42);
      for (var i = 0; i < 1000; i++) {
        final failures = i % 7;
        const steps = WebSocketConstants.backoffSteps;
        final step = steps[min(failures, steps.length - 1)];
        final delay = backoffDelay(failures, random: random);
        expect(delay, greaterThanOrEqualTo(step * 0.8));
        expect(delay, lessThanOrEqualTo(step * 1.2));
      }
    });
  });

  group('isHandshakeUnauthorized', () {
    test('a 401 on the upgrade request is the server refusing the token', () {
      expect(
        isHandshakeUnauthorized(
          WebSocketChannelException.from(
            const WebSocketException(
              'Connection was not upgraded to websocket',
              401,
            ),
          ),
        ),
        isTrue,
      );
    });

    test('an unwrapped 401 counts too', () {
      expect(
        isHandshakeUnauthorized(const WebSocketException('Not upgraded', 401)),
        isTrue,
      );
    });

    test('a 500 on the upgrade request is not', () {
      expect(
        isHandshakeUnauthorized(
          WebSocketChannelException.from(
            const WebSocketException('Not upgraded', 500),
          ),
        ),
        isFalse,
      );
    });

    test('a refused connection is not', () {
      expect(
        isHandshakeUnauthorized(
          WebSocketChannelException.from(
            const SocketException('Connection refused'),
          ),
        ),
        isFalse,
      );
    });

    test('a handshake that timed out is not', () {
      expect(
        isHandshakeUnauthorized(
          TimeoutException(
            'WebSocket handshake timed out',
            const Duration(seconds: 10),
          ),
        ),
        isFalse,
      );
    });
  });

  group('tokenNeedsRefresh', () {
    final now = DateTime.utc(2026, 10, 14, 12);
    final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;

    test('a token valid for more than a minute is used as is', () {
      expect(tokenNeedsRefresh(_jwt({'exp': nowSeconds + 61}), now), isFalse);
    });

    test('a token that expires within a minute is refreshed', () {
      expect(tokenNeedsRefresh(_jwt({'exp': nowSeconds + 60}), now), isTrue);
      expect(tokenNeedsRefresh(_jwt({'exp': nowSeconds + 1}), now), isTrue);
    });

    test('an expired token is refreshed', () {
      expect(tokenNeedsRefresh(_jwt({'exp': nowSeconds - 10}), now), isTrue);
    });

    test('a token without a readable exp is refreshed', () {
      expect(tokenNeedsRefresh('not-a-jwt', now), isTrue);
      expect(tokenNeedsRefresh(_jwt({'sub': 'user-1'}), now), isTrue);
      expect(tokenNeedsRefresh(_jwt({'exp': 'tomorrow'}), now), isTrue);
    });

    test('odd claims elsewhere in the token are ignored', () {
      expect(
        tokenNeedsRefresh(
          _jwt({'exp': nowSeconds + 600, 'kycVerified': 'yes'}),
          now,
        ),
        isFalse,
      );
    });
  });

  group('interpretCloseCode', () {
    test('maps every close code the protocol defines', () {
      expect(interpretCloseCode(1000), WebSocketCloseMeaning.normal);
      expect(interpretCloseCode(4001), WebSocketCloseMeaning.tokenExpired);
      expect(interpretCloseCode(4002), WebSocketCloseMeaning.rateLimited);
      expect(interpretCloseCode(4003), WebSocketCloseMeaning.authRevoked);
      expect(interpretCloseCode(4004), WebSocketCloseMeaning.serverShutdown);
    });

    test('anything else is transient: no close frame, idle, bad frame, error',
        () {
      for (final code in [null, 1001, 1006, 1008, 1011]) {
        expect(
          interpretCloseCode(code),
          WebSocketCloseMeaning.transient,
          reason: 'close code $code',
        );
      }
    });
  });
}
