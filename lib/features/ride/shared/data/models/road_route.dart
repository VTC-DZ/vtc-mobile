import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    return RoadRoute(
      // GeoJSON positions are [lng, lat].
      points: coordinates.map((c) {
        final position = c as List<dynamic>;
        return LatLng(
          (position[1] as num).toDouble(),
          (position[0] as num).toDouble(),
        );
      }).toList(),
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [points, distanceMeters, durationSeconds];
}
