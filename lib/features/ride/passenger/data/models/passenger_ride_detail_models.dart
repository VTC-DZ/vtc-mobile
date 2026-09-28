import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/utils/map_geo.dart';
import 'passenger_ride_models.dart';

/// Detail for a single ride, from `GET /api/passenger/rides/{rideRequestId}`.
///
/// Matches the `RideDetailResponse` schema in `swagger/passenger.json`. Unlike
/// the driver's detail it carries no addresses, service type or cancellation
/// reason — the screen takes those from the tapped `PassengerRideHistoryItem`
/// and adds the driver's contact, the full timeline, trip facts and the route.
final class PassengerRideDetail {
  const PassengerRideDetail({
    required this.rideId,
    required this.state,
    required this.finalFare,
    this.driver,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.distanceMeters,
    this.durationSeconds,
    this.routePoints,
  });

  final String rideId;
  final RideOutcome state;
  final int finalFare;
  final DriverInRide? driver;
  final String? acceptedAt;
  final String? arrivedAt;
  final String? startedAt;
  final String? completedAt;
  final String? cancelledAt;
  final int? distanceMeters;
  final int? durationSeconds;

  /// Travelled path from `routeGeometryGeoJson`; `null` when absent or not a
  /// GeoJSON `LineString`.
  final List<LatLng>? routePoints;

  factory PassengerRideDetail.fromJson(Map<String, dynamic> json) {
    final fare = json['finalFare'];
    final driver = json['driver'];
    return PassengerRideDetail(
      rideId: (json['rideId'] as String?) ?? '',
      state: RideOutcome.fromJson((json['state'] as String?) ?? ''),
      finalFare: fare is int ? fare : ((fare as num?)?.toInt() ?? 0),
      driver: driver is Map<String, dynamic>
          ? DriverInRide.fromJson(driver)
          : null,
      acceptedAt: json['acceptedAt'] as String?,
      arrivedAt: json['arrivedAt'] as String?,
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
      distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      routePoints: MapGeo.lineStringPoints(json['routeGeometryGeoJson']),
    );
  }
}
