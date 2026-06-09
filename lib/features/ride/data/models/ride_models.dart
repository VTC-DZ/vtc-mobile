import 'service_type.dart';
import 'vehicle_category.dart';

export 'service_type.dart';
export 'vehicle_category.dart';

final class CoordinatePoint {
  const CoordinatePoint({
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String address;
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {
        'address': address,
        'lat': lat,
        'lng': lng,
      };
}

final class CreateRideRequest {
  const CreateRideRequest({
    required this.pickup,
    required this.dropoff,
    required this.serviceType,
    required this.vehicleCategory,
    required this.femaleOnly,
    required this.proposedFare,
  });

  final CoordinatePoint pickup;
  final CoordinatePoint dropoff;
  final ServiceType serviceType;
  final VehicleCategory vehicleCategory;
  final bool femaleOnly;
  final int proposedFare;

  Map<String, dynamic> toJson() => {
        'pickup': pickup.toJson(),
        'dropoff': dropoff.toJson(),
        'serviceType': serviceType.toJson(),
        'vehicleCategory': vehicleCategory.toJson(),
        'femaleOnly': femaleOnly,
        'proposedFare': proposedFare,
      };
}

final class CreateRideResponse {
  const CreateRideResponse({
    required this.rideRequestId,
    required this.state,
    required this.proposedFare,
    required this.expiresAt,
    required this.broadcastDriverCount,
  });

  final String rideRequestId;
  final String state;
  final int proposedFare;
  final String expiresAt;
  final int broadcastDriverCount;

  factory CreateRideResponse.fromJson(Map<String, dynamic> json) =>
      CreateRideResponse(
        rideRequestId: json['rideRequestId'] as String,
        state: json['state'] as String,
        proposedFare: json['proposedFare'] as int,
        expiresAt: json['expiresAt'] as String,
        broadcastDriverCount: json['broadcastDriverCount'] as int,
      );
}
