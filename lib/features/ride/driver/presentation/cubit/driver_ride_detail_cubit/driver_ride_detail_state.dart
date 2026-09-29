import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/driver_ride_detail_models.dart';

enum DriverRideDetailStatus { initial, loading, loaded, failure }

final class DriverRideDetailState extends Equatable {
  const DriverRideDetailState({
    this.status = DriverRideDetailStatus.initial,
    this.ride,
    this.routePoints,
    this.errorMessage = '',
  });

  final DriverRideDetailStatus status;
  final DriverRideDetail? ride;

  /// Pickup → drop-off road path for the hero map; a straight line when
  /// routing failed, `null` until known (or when the ride has no coordinates).
  final List<LatLng>? routePoints;
  final String errorMessage;

  DriverRideDetailState copyWith({
    DriverRideDetailStatus? status,
    DriverRideDetail? ride,
    List<LatLng>? routePoints,
    String? errorMessage,
  }) {
    return DriverRideDetailState(
      status: status ?? this.status,
      ride: ride ?? this.ride,
      routePoints: routePoints ?? this.routePoints,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, ride, routePoints, errorMessage];
}
