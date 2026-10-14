/// WebSocket protocol constants — raw socket transport for the ride surfaces.
///
/// See `swagger/epic-03-ride.md` §4 and `swagger/websocket.json`. The close-code
/// meanings and the reconnect decisions are in `ride_socket_policy.dart`.
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

  /// The client's ping is what keeps the socket open: the server never pings,
  /// and Tomcat closes a session after 60 s with no inbound frame
  /// (`heartbeat-interval-s` × 2). A pong must come back within one interval,
  /// so a dead link is noticed within about 20 s, under the server's 30 s
  /// limit on how old a driver's position may be.
  static const Duration pingInterval = Duration(seconds: 10);

  /// How long a handshake may take before the attempt is given up and retried
  /// on the backoff.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Reconnect backoff ladder: 1s → 2s → 4s → 8s → 16s (cap). See runbook §4.
  static const List<Duration> backoffSteps = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
  ];

  /// Each backoff step is spread by up to ±20 %, so the clients a server
  /// restart drops all at once don't all come back at once.
  static const double backoffJitter = 0.2;

  /// The server checks the access token only at the handshake, so a token
  /// that expires within this margin is refreshed before connecting.
  static const Duration tokenRefreshMargin = Duration(seconds: 60);
}
