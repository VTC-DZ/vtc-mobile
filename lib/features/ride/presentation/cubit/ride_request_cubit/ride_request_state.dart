import 'package:equatable/equatable.dart';

import '../../../data/models/ride_models.dart';

enum RideRequestStatus { initial, loading, success, failure }

final class RideRequestState extends Equatable {
  const RideRequestState({
    this.serviceType = ServiceType.ride,
    this.vehicleCategory = VehicleCategory.car,
    this.femaleOnly = false,
    this.status = RideRequestStatus.initial,
    this.errorMessage = '',
    this.createRideResponse,
  });

  final ServiceType serviceType;
  final VehicleCategory vehicleCategory;
  final bool femaleOnly;
  final RideRequestStatus status;
  final String errorMessage;
  final CreateRideResponse? createRideResponse;

  RideRequestState copyWith({
    ServiceType? serviceType,
    VehicleCategory? vehicleCategory,
    bool? femaleOnly,
    RideRequestStatus? status,
    String? errorMessage,
    CreateRideResponse? createRideResponse,
  }) =>
      RideRequestState(
        serviceType: serviceType ?? this.serviceType,
        vehicleCategory: vehicleCategory ?? this.vehicleCategory,
        femaleOnly: femaleOnly ?? this.femaleOnly,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        createRideResponse: createRideResponse ?? this.createRideResponse,
      );

  @override
  List<Object?> get props => [
        serviceType,
        vehicleCategory,
        femaleOnly,
        status,
        errorMessage,
        createRideResponse,
      ];
}
