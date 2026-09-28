import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Road routing via the public OSRM demo server.
///
/// The demo server has no SLA and its usage policy rules out production
/// traffic — swap [baseUrl] (or the whole `RoutingRepository`) for a backend
/// routing endpoint before release.
abstract final class RoutingApiConstants {
  RoutingApiConstants._();

  static const String baseUrl = 'https://router.project-osrm.org';

  static const int connectTimeoutMs = 8000;
  static const int receiveTimeoutMs = 8000;

  /// Driving route [from] → [to]. OSRM takes coordinates as `lng,lat`.
  static String drivingRoute(LatLng from, LatLng to) => '/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';

  /// Full-resolution geometry as GeoJSON — no polyline decoding needed.
  static const Map<String, String> routeQuery = {
    'overview': 'full',
    'geometries': 'geojson',
  };
}
