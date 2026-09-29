import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/api_exception.dart';
import '../../../../../../core/models/token_payload.dart';
import '../../../../../../core/network/ride_socket_service.dart';
import '../../../../driver/data/models/ride_socket_event.dart';
import '../../../../shared/models/shared_ride_models.dart';
import '../../../data/models/passenger_ride_models.dart';
import '../../../data/passenger_ride_repository.dart';
import 'passenger_active_ride_state.dart';

final class PassengerActiveRideCubit extends Cubit<PassengerActiveRideState> {
  PassengerActiveRideCubit(this._repository)
      : super(const PassengerActiveRideState()) {
    _frameSub = RideSocketService.frameStream.listen(_onFrame);
    _statusSub = RideSocketService.statusStream.listen(_onStatus);
  }

  final PassengerRideRepository _repository;
  late final StreamSubscription<String> _frameSub;
  late final StreamSubscription<RideSocketStatus> _statusSub;

  // REST is truth, WS is hints: frames sent while the socket was down are lost,
  // so reconcile against /rides/active every time it comes back up.
  void _onStatus(RideSocketStatus status) {
    if (status != RideSocketStatus.connected) return;
    // Only once a ride is on screen: before that, the initial load is still in
    // flight, and after a terminal state the view is already navigating away.
    if (state.status != PassengerActiveRideStatus.loaded &&
        state.status != PassengerActiveRideStatus.actionFailure) {
      return;
    }
    _reconcile();
  }

  // Silent refetch — no loading emit, so the trip screen doesn't flash a
  // spinner, and a failed reconcile keeps the last known ride on screen.
  Future<void> _reconcile() async {
    final rideRequestId = state.ride?.rideRequestId;
    if (rideRequestId == null) return;
    try {
      final ride = (await _repository.getActiveRide()).ride;
      if (isClosed) return;
      if (ride != null) {
        emit(state.copyWith(
          ride: ride,
          driverLat: ride.driver.currentLat,
          driverLng: ride.driver.currentLng,
        ));
        _handleStateChange(RideState.fromWire(ride.state));
        return;
      }
      // The ride ended while the socket was down — the driver may have
      // completed it, so ask the detail endpoint how it ended.
      final detail = await _repository.getRideDetail(rideRequestId);
      if (isClosed) return;
      _handleStateChange(detail.state == RideOutcome.completed
          ? RideState.completed
          : RideState.cancelled);
    } catch (_) {
      // Keep the last known state; the next state frame or reconnect retries.
    }
  }

  Future<void> loadActiveRide() async {
    emit(state.copyWith(
        status: PassengerActiveRideStatus.loading, errorMessage: ''));
    try {
      final result = await _repository.getActiveRide();
      final ride = result.ride;
      if (ride == null) {
        emit(state.copyWith(
            status: PassengerActiveRideStatus.failure,
            errorMessage: 'No active ride found'));
        return;
      }
      await RideSocketService.connect(ActiveRole.passenger);
      emit(state.copyWith(
        status: PassengerActiveRideStatus.loaded,
        ride: ride,
        rideState: RideState.fromWire(ride.state),
        driverLat: ride.driver.currentLat,
        driverLng: ride.driver.currentLng,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PassengerActiveRideStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> cancelRide(CancelReason reason, {String? note}) async {
    final rideRequestId = state.ride?.rideRequestId;
    if (rideRequestId == null) return;
    try {
      await _repository.cancelRide(
        rideRequestId,
        CancelRideRequest(reason: reason.apiValue, note: note),
      );
      emit(state.copyWith(status: PassengerActiveRideStatus.cancelled));
    } catch (e) {
      if (isClosed) return;
      // 409 = stale view (e.g. the trip already started) — re-render from
      // server state instead of showing an error.
      if (e is ApiException && e.isConflict) {
        _reconcile();
        return;
      }
      emit(state.copyWith(
        status: PassengerActiveRideStatus.actionFailure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onFrame(String frame) {
    final event = RideSocketEvent.tryParse(frame);
    switch (event) {
      case RideStateChanged(state: final rideState):
        _handleStateChange(rideState);
      case RideCancelled():
        emit(state.copyWith(status: PassengerActiveRideStatus.cancelled));
      case DriverLocationUpdate(:final lat, :final lng):
        log(
          '[PassengerActiveRide] DriverLocationUpdate — rideState: ${state.rideState}, lat: $lat, lng: $lng',
          name: 'PassengerActiveRideCubit',
        );
        emit(state.copyWith(driverLat: lat, driverLng: lng));
      default:
        break;
    }
  }

  void _handleStateChange(RideState newState) {
    if (newState == RideState.completed) {
      emit(state.copyWith(
          status: PassengerActiveRideStatus.completed, rideState: newState));
    } else if (newState == RideState.cancelled) {
      emit(state.copyWith(
          status: PassengerActiveRideStatus.cancelled, rideState: newState));
    } else {
      emit(state.copyWith(
          status: PassengerActiveRideStatus.loaded, rideState: newState));
    }
  }

  @override
  Future<void> close() {
    _frameSub.cancel();
    _statusSub.cancel();
    return super.close();
  }
}
