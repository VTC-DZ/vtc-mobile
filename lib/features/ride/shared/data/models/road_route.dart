import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/utils/map_geo.dart';

/// A driving route that follows the road network.
final class RoadRoute extends Equatable {
  const RoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Path from origin to destination, in travel order.
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  /// Parses an OSRM `/route` response requested with `geometries=geojson`.
  /// Throws a [FormatException] when OSRM found no route.
  factory RoadRoute.fromOsrmJson(Map<String, dynamic> json) {
    final routes = json['routes'] as List<dynamic>? ?? const [];
    if (json['code'] != 'Ok' || routes.isEmpty) {
      throw FormatException('No route found (${json['code']})');
    }
    final route = routes.first as Map<String, dynamic>;
    final points = MapGeo.lineStringPoints(route['geometry']);
    if (points == null) {
      throw const FormatException('Route geometry is not a LineString');
    }
    return RoadRoute(
      points: points,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [points, distanceMeters, durationSeconds];
}
