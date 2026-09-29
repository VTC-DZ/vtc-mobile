import 'package:equatable/equatable.dart';

import '../../../data/models/passenger_ride_models.dart';

/// `alreadyActive` = a request/ride is already live (resume it); `cooldown` =
/// inside the post-cancel window, see [RideRequestState.cooldownSeconds].
enum RideRequestStatus {
  initial,
  loading,
  success,
  failure,
  alreadyActive,
  cooldown,
}

final class RideRequestState extends Equatable {
  const RideRequestState({
    this.serviceType = ServiceType.ride,
    this.vehicleCategory = VehicleCategory.car,
    this.femaleOnly = false,
    this.status = RideRequestStatus.initial,
    this.errorMessage = '',
    this.createRideResponse,
    this.cooldownSeconds = 0,
  });

  final ServiceType serviceType;
  final VehicleCategory vehicleCategory;
  final bool femaleOnly;
  final RideRequestStatus status;
  final String errorMessage;
  final CreateRideResponse? createRideResponse;

  /// Seconds left before a new request is allowed; `0` when not cooling down.
  final int cooldownSeconds;

  RideRequestState copyWith({
    ServiceType? serviceType,
    VehicleCategory? vehicleCategory,
    bool? femaleOnly,
    RideRequestStatus? status,
    String? errorMessage,
    CreateRideResponse? createRideResponse,
    int? cooldownSeconds,
  }) =>
      RideRequestState(
        serviceType: serviceType ?? this.serviceType,
        vehicleCategory: vehicleCategory ?? this.vehicleCategory,
        femaleOnly: femaleOnly ?? this.femaleOnly,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        createRideResponse: createRideResponse ?? this.createRideResponse,
        cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      );

  @override
  List<Object?> get props => [
        serviceType,
        vehicleCategory,
        femaleOnly,
        status,
        errorMessage,
        createRideResponse,
        cooldownSeconds,
      ];
}
