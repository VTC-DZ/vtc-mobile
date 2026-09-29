import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/data/routing_repository.dart';
import '../../../data/driver_ride_repository.dart';
import '../../../data/models/driver_ride_detail_models.dart';
import 'driver_ride_detail_state.dart';

/// Loads the full detail of a single past ride, then its road route for the
/// hero map.
class DriverRideDetailCubit extends Cubit<DriverRideDetailState> {
  DriverRideDetailCubit(
    this._repository,
    this._routingRepository, {
    required String rideId,
  })  : _rideId = rideId,
        super(const DriverRideDetailState());

  final DriverRideRepository _repository;
  final RoutingRepository _routingRepository;
  final String _rideId;

  Future<void> load() async {
    emit(state.copyWith(
      status: DriverRideDetailStatus.loading,
      errorMessage: '',
    ));
    try {
      final ride = await _repository.getRideDetail(_rideId);
      emit(state.copyWith(status: DriverRideDetailStatus.loaded, ride: ride));
      await _loadRoute(ride);
    } catch (e) {
      emit(state.copyWith(
        status: DriverRideDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Best effort: the map is decoration, so a routing failure falls back to a
  /// straight pickup → drop-off line and never fails the screen.
  Future<void> _loadRoute(DriverRideDetail ride) async {
    final pickupLat = ride.pickupLat;
    final pickupLng = ride.pickupLng;
    final dropoffLat = ride.dropoffLat;
    final dropoffLng = ride.dropoffLng;
    if (pickupLat == null ||
        pickupLng == null ||
        dropoffLat == null ||
        dropoffLng == null) {
      return;
    }
    final pickup = LatLng(pickupLat, pickupLng);
    final dropoff = LatLng(dropoffLat, dropoffLng);
    List<LatLng> points;
    try {
      points = (await _routingRepository.drivingRoute(pickup, dropoff)).points;
    } catch (_) {
      points = [pickup, dropoff];
    }
    if (!isClosed) emit(state.copyWith(routePoints: points));
  }
}
