import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/driver_ride_repository.dart';
import '../../../data/models/driver_ride_models.dart';
import 'driver_active_ride_state.dart';

final class DriverActiveRideCubit extends Cubit<DriverActiveRideState> {
  DriverActiveRideCubit(this._repository)
      : super(const DriverActiveRideState());

  final DriverRideRepository _repository;

  Future<void> loadActiveRide() async {
    emit(state.copyWith(
        status: DriverActiveRideStatus.loading, errorMessage: ''));
    try {
      final ride = await _repository.getActiveRide();
      if (ride == null) {
        emit(state.copyWith(status: DriverActiveRideStatus.noActiveRide));
      } else {
        emit(state.copyWith(status: DriverActiveRideStatus.loaded, ride: ride));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DriverActiveRideStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> markArrived() async {
    final rideId = state.ride?.rideId;
    if (rideId == null) return;
    emit(state.copyWith(status: DriverActiveRideStatus.transitioning));
    try {
      await _repository.markArrived(rideId);
      await loadActiveRide();
    } catch (e) {
      emit(state.copyWith(
        status: DriverActiveRideStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> startRide() async {
    final rideId = state.ride?.rideId;
    if (rideId == null) return;
    emit(state.copyWith(status: DriverActiveRideStatus.transitioning));
    try {
      await _repository.startRide(rideId);
      await loadActiveRide();
    } catch (e) {
      emit(state.copyWith(
        status: DriverActiveRideStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> completeRide() async {
    final rideId = state.ride?.rideId;
    if (rideId == null) return;
    emit(state.copyWith(status: DriverActiveRideStatus.transitioning));
    try {
      await _repository.completeRide(rideId);
      await loadActiveRide();
    } catch (e) {
      emit(state.copyWith(
        status: DriverActiveRideStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> cancelRide(CancelReason reason, {String? note}) async {
    final rideId = state.ride?.rideId;
    if (rideId == null) return;
    emit(state.copyWith(status: DriverActiveRideStatus.transitioning));
    try {
      await _repository.cancelRide(
        rideId,
        DriverCancelRequest(reason: reason.apiValue, note: note),
      );
      await loadActiveRide();
    } catch (e) {
      emit(state.copyWith(
        status: DriverActiveRideStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
