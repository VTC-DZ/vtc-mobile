/// WebSocket protocol constants — raw socket transport for the ride surfaces.
///
/// See `swagger/epic-03-ride.md` §4 and `swagger/websocket.json`.
abstract final class WebSocketConstants {
  WebSocketConstants._();

  /// Surface endpoints, appended to [wsBaseUrl].
  static const String driverEndpoint = '/ws/driver';
  static const String passengerEndpoint = '/ws/passenger';

  // --- Close codes (server → client) ---
  static const int closeNormal = 1000; // normal closure — do NOT reconnect
  static const int closeTokenExpired = 4001; // refresh via REST, reconnect fresh
  static const int closeRateLimited = 4002; // back off, then reconnect
  static const int closeAuthRevoked = 4003; // user blocked / role lost — force re-login
  static const int closeServerShutdown = 4004; // reconnect with backoff

  /// Server emits a WS ping every ~30s; the client library auto-answers with a
  /// pong. Set on the channel so the transport also keeps the link warm.
  static const Duration pingInterval = Duration(seconds: 30);

  /// Reconnect backoff ladder: 1s → 2s → 4s → 8s → 16s (cap). See runbook §4.
  static const List<Duration> backoffSteps = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
  ];
}

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
