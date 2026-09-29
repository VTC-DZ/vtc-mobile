import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/network/ride_socket_service.dart';
import '../../../data/driver_ride_repository.dart';
import '../../../data/models/driver_ride_models.dart';
import '../../../data/models/ride_socket_event.dart';
import 'driver_active_ride_state.dart';

final class DriverActiveRideCubit extends Cubit<DriverActiveRideState> {
  DriverActiveRideCubit(this._repository)
      : super(const DriverActiveRideState()) {
    _frameSub = RideSocketService.frameStream.listen(_onFrame);
    _statusSub = RideSocketService.statusStream.listen(_onStatus);
  }

  final DriverRideRepository _repository;
  late final StreamSubscription<String> _frameSub;
  late final StreamSubscription<RideSocketStatus> _statusSub;

  // REST is truth, WS is hints: frames sent while the socket was down are lost,
  // so reconcile against /rides/active every time it comes back up.
  void _onStatus(RideSocketStatus status) {
    if (status != RideSocketStatus.connected) return;
    // Only once a ride is on screen: before that, the view's initial load is
    // still in flight. Skip while an action is in flight (it reloads itself)
    // and after a terminal state (the view is already navigating away).
    if (state.status != DriverActiveRideStatus.loaded &&
        state.status != DriverActiveRideStatus.actionFailure) {
      return;
    }
    _reconcile();
  }

  void _onFrame(String frame) {
    final event = RideSocketEvent.tryParse(frame);
    switch (event) {
      case RideStateChanged():
        loadActiveRide();
      case RideCancelled():
        emit(state.copyWith(status: DriverActiveRideStatus.cancelled));
      default:
        break;
    }
  }

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

  // Silent refetch — no loading emit, so the trip screen doesn't flash a
  // spinner, and a failed reconcile keeps the last known ride on screen.
  Future<void> _reconcile() async {
    try {
      final ride = await _repository.getActiveRide();
      if (isClosed) return;
      if (ride == null) {
        // The ride ended while the socket was down. Only the driver can
        // complete it, so another party cancelled it — go home.
        emit(state.copyWith(status: DriverActiveRideStatus.cancelled));
      } else {
        emit(state.copyWith(status: DriverActiveRideStatus.loaded, ride: ride));
      }
    } catch (_) {
      // Keep the last known state; the next state frame or reconnect retries.
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
        status: DriverActiveRideStatus.actionFailure,
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
        status: DriverActiveRideStatus.actionFailure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> completeRide() async {
    final rideId = state.ride?.rideId;
    if (rideId == null) return;
    emit(state.copyWith(status: DriverActiveRideStatus.transitioning));
    try {
      final response = await _repository.completeRide(rideId);
      emit(state.copyWith(
        status: DriverActiveRideStatus.completed,
        completedFare: response.finalFare,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DriverActiveRideStatus.actionFailure,
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
        status: DriverActiveRideStatus.actionFailure,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _frameSub.cancel();
    _statusSub.cancel();
    return super.close();
  }
}
