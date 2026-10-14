/// The decisions behind `RideSocketService`'s connection flow, as pure
/// functions so they can be unit-tested without a socket.
library;

import 'dart:io' show WebSocketException;
import 'dart:math' show Random;

import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/web_socket_constants.dart';
import '../utils/jwt_decoder.dart';

/// Typed meaning for a close code, so callers switch on intent rather than ints.
enum WebSocketCloseMeaning {
  normal, // 1000 — intentional stop
  tokenExpired, // 4001 — refresh + reconnect
  rateLimited, // 4002 — backoff reconnect
  authRevoked, // 4003 — force re-login (clear session)
  serverShutdown, // 4004 — backoff reconnect
  transient, // unknown / null — backoff reconnect
}

/// Maps a close code to its [WebSocketCloseMeaning]. Unknown or null codes
/// (e.g. a dropped TCP link with no close frame) are treated as [transient].
WebSocketCloseMeaning interpretCloseCode(int? code) {
  return switch (code) {
    WebSocketConstants.closeNormal => WebSocketCloseMeaning.normal,
    WebSocketConstants.closeTokenExpired => WebSocketCloseMeaning.tokenExpired,
    WebSocketConstants.closeRateLimited => WebSocketCloseMeaning.rateLimited,
    WebSocketConstants.closeAuthRevoked => WebSocketCloseMeaning.authRevoked,
    WebSocketConstants.closeServerShutdown =>
      WebSocketCloseMeaning.serverShutdown,
    _ => WebSocketCloseMeaning.transient,
  };
}

final _random = Random();

/// How long to wait before the next attempt after [failures] consecutive
/// failed ones: [WebSocketConstants.backoffSteps] (1 → 2 → 4 → 8 → 16 s, then
/// 16 s from there on), each spread by ±[WebSocketConstants.backoffJitter].
Duration backoffDelay(int failures, {Random? random}) {
  const steps = WebSocketConstants.backoffSteps;
  final step = steps[failures.clamp(0, steps.length - 1)];
  // nextDouble() is in [0, 1), so the spread is in [-1, 1).
  final spread = (random ?? _random).nextDouble() * 2 - 1;
  return step * (1 + WebSocketConstants.backoffJitter * spread);
}

/// Whether a failed handshake means the server refused the token. It answers
/// the upgrade request with HTTP 401 for a missing, invalid or expired token,
/// and for a non-`DRIVER` token on `/ws/driver`; the channel reports that as a
/// [WebSocketChannelException] wrapping `dart:io`'s [WebSocketException].
bool isHandshakeUnauthorized(Object error) {
  final inner = error is WebSocketChannelException ? error.inner : error;
  return inner is WebSocketException && inner.httpStatusCode == 401;
}

/// Whether [token] expires within [WebSocketConstants.tokenRefreshMargin] of
/// [now], so it must be refreshed before a handshake. A token without a
/// readable `exp` counts as expired.
bool tokenNeedsRefresh(String token, DateTime now) {
  // Read the claim directly: TokenPayload's casts throw on an odd claim, and
  // a throw here would leave the reconnect loop stuck.
  final exp = JwtDecoder.decode(token)['exp'];
  if (exp is! num) return true;
  final expiresAt = DateTime.fromMillisecondsSinceEpoch(
    (exp * 1000).toInt(),
    isUtc: true,
  );
  return !expiresAt.isAfter(now.add(WebSocketConstants.tokenRefreshMargin));
}
