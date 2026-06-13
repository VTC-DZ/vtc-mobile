import 'package:equatable/equatable.dart';

import '../../../data/models/driver_ride_models.dart';

enum DriverActiveRideStatus {
  initial,
  loading,
  loaded,
  transitioning,
  noActiveRide,
  failure,
}

final class DriverActiveRideState extends Equatable {
  const DriverActiveRideState({
    this.status = DriverActiveRideStatus.initial,
    this.ride,
    this.errorMessage = '',
  });

  final DriverActiveRideStatus status;
  final ActiveDriverRideResponse? ride;
  final String errorMessage;

  DriverActiveRideState copyWith({
    DriverActiveRideStatus? status,
    ActiveDriverRideResponse? ride,
    String? errorMessage,
  }) =>
      DriverActiveRideState(
        status: status ?? this.status,
        ride: ride ?? this.ride,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, ride, errorMessage];
}
