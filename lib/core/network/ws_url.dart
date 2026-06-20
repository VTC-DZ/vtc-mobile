import '../constants/api_constants.dart';

/// Derives the WebSocket base URL from the REST [ApiConstants.baseUrl].
///
/// Swaps the HTTP scheme for the matching WebSocket scheme so the WS endpoint
/// always tracks the configured REST host:
///   `http://localhost:8080`  -> `ws://localhost:8080`
///   `https://api.example`    -> `wss://api.example`
///
/// `ApiConstants.baseUrl` is the single source of truth — do not introduce a
/// second `wsBaseUrl` constant that can drift.
///
/// Note for the Android emulator: when the backend runs on the dev host,
/// `baseUrl` must point at `10.0.2.2` (not `localhost`). Keep that concern in
/// [ApiConstants] rather than branching on platform here.
String wsBaseUrl() {
  const base = ApiConstants.baseUrl;
  if (base.startsWith('https://')) return 'wss://${base.substring(8)}';
  if (base.startsWith('http://')) return 'ws://${base.substring(7)}';
  // Fall back to a ws:// scheme if the configured base is unconventional.
  return 'ws://$base';
}
