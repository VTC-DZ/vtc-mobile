import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:khfif_drif/features/ride/passenger/data/models/passenger_ride_detail_models.dart';
import 'package:khfif_drif/features/ride/shared/models/shared_ride_models.dart';

/// Fixtures mirror the `RideDetailResponse` schema in `swagger/passenger.json`.
void main() {
  group('PassengerRideDetail.fromJson', () {
    test('maps a full payload field by field', () {
      final ride = PassengerRideDetail.fromJson({
        'rideId': 'ride-uuid',
        'state': 'COMPLETED',
        'finalFare': 1250,
        'driver': {
          'id': 'driver-uuid',
          'fullName': 'Karim D',
          'phone': '+213660000000',
          'vehicleModel': 'Renault Symbol',
          'vehiclePlate': '12345-116-16',
          'currentPosition': {'lat': 36.7, 'lng': 3.2},
          'etaSeconds': 0,
        },
        'acceptedAt': '2026-09-20T10:00:00Z',
        'arrivedAt': '2026-09-20T10:05:00Z',
        'startedAt': '2026-09-20T10:06:00Z',
        'completedAt': '2026-09-20T10:28:00Z',
        'distanceMeters': 8400,
        'durationSeconds': 1320,
        'routeGeometryGeoJson': {
          'type': 'LineString',
          'coordinates': [
            [3.0602, 36.7753],
            [3.2154, 36.6979],
          ],
        },
      });

      expect(ride.rideId, 'ride-uuid');
      expect(ride.state, RideOutcome.completed);
      expect(ride.finalFare, 1250);
      expect(ride.driver?.id, 'driver-uuid');
      expect(ride.driver?.fullName, 'Karim D');
      expect(ride.driver?.phone, '+213660000000');
      expect(ride.driver?.vehicleModel, 'Renault Symbol');
      expect(ride.driver?.vehiclePlate, '12345-116-16');
      expect(ride.driver?.currentLat, 36.7);
      expect(ride.driver?.currentLng, 3.2);
      expect(ride.acceptedAt, '2026-09-20T10:00:00Z');
      expect(ride.arrivedAt, '2026-09-20T10:05:00Z');
      expect(ride.startedAt, '2026-09-20T10:06:00Z');
      expect(ride.completedAt, '2026-09-20T10:28:00Z');
      expect(ride.cancelledAt, isNull);
      expect(ride.distanceMeters, 8400);
      expect(ride.durationSeconds, 1320);
      expect(ride.routePoints, const [
        LatLng(36.7753, 3.0602),
        LatLng(36.6979, 3.2154),
      ]);
    });

    test('tolerates a sparse cancelled payload', () {
      final ride = PassengerRideDetail.fromJson({
        'rideId': 'ride-2',
        'state': 'CANCELLED',
        'finalFare': 900.0,
        'driver': {'fullName': 'Karim D'},
        'acceptedAt': '2026-09-20T10:00:00Z',
        'cancelledAt': '2026-09-20T10:03:00Z',
      });

      expect(ride.state, RideOutcome.cancelled);
      expect(ride.finalFare, 900);
      expect(ride.driver?.fullName, 'Karim D');
      expect(ride.driver?.phone, '');
      expect(ride.driver?.vehiclePlate, '');
      expect(ride.driver?.currentLat, isNull);
      expect(ride.cancelledAt, '2026-09-20T10:03:00Z');
      expect(ride.completedAt, isNull);
      expect(ride.distanceMeters, isNull);
      expect(ride.durationSeconds, isNull);
      expect(ride.routePoints, isNull);
    });

    test('leaves driver and route null when absent or malformed', () {
      final ride = PassengerRideDetail.fromJson({
        'rideId': 'ride-3',
        'state': 'COMPLETED',
        'finalFare': 500,
        'routeGeometryGeoJson': <String, dynamic>{},
      });

      expect(ride.driver, isNull);
      expect(ride.routePoints, isNull);
    });
  });
}
