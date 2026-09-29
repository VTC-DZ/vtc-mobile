import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/constants/ride_api_constants.dart';
import '../../../../../../core/errors/api_exception.dart';
import '../../../../../../core/models/token_payload.dart';
import '../../../../../../core/network/ride_socket_service.dart';
import '../../../data/models/passenger_ride_models.dart';
import '../../../data/passenger_ride_repository.dart';
import 'ride_request_state.dart';

final class RideRequestCubit extends Cubit<RideRequestState> {
  RideRequestCubit(this._repository) : super(const RideRequestState());

  final PassengerRideRepository _repository;
  Timer? _cooldownTimer;

  /// Used only when the `429` carries no `Retry-After` header — the server
  /// default of `ride.cancellation-cooldown-s` (swagger/epic-03-ride.md §7).
  static const _fallbackCooldown = Duration(seconds: 30);

  void setServiceType(ServiceType value) {
    // If the current vehicle category isn't available for the new service
    // type (e.g. motorcycle under Delivery, van under Ride), fall back to car.
    final validCategories = value.availableCategories;
    final newCategory = validCategories.contains(state.vehicleCategory)
        ? state.vehicleCategory
        : VehicleCategory.car;
    emit(state.copyWith(serviceType: value, vehicleCategory: newCategory));
  }

  void setVehicleCategory(VehicleCategory value) =>
      emit(state.copyWith(vehicleCategory: value));

  void setFemaleOnly(bool value) => emit(state.copyWith(femaleOnly: value));

  Future<void> submitRide(CreateRideRequest request) async {
    emit(state.copyWith(status: RideRequestStatus.loading, errorMessage: ''));
    try {
      final response = await _repository.createRide(request);
      await RideSocketService.connect(ActiveRole.passenger);
      if (kDebugMode) debugPrint('[Passenger] WS connected for ride ${response.rideRequestId}');
      emit(state.copyWith(
        status: RideRequestStatus.success,
        createRideResponse: response,
      ));
    } catch (e) {
      if (isClosed) return;
      if (e is ApiException &&
          e.hasCode(PassengerRideErrorCodes.rideAlreadyActive)) {
        emit(state.copyWith(status: RideRequestStatus.alreadyActive));
        return;
      }
      if (e is ApiException &&
          e.hasCode(PassengerRideErrorCodes.rideCreateCooldown)) {
        _startCooldown(e.retryAfter ?? _fallbackCooldown, e.message);
        return;
      }
      emit(state.copyWith(
        status: RideRequestStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Counts down the post-cancel window, then re-enables submitting.
  void _startCooldown(Duration duration, String message) {
    _cooldownTimer?.cancel();
    emit(state.copyWith(
      status: RideRequestStatus.cooldown,
      cooldownSeconds: duration.inSeconds.clamp(1, 3600),
      errorMessage: message,
    ));
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.cooldownSeconds - 1;
      if (left <= 0) {
        timer.cancel();
        emit(state.copyWith(
            status: RideRequestStatus.initial, cooldownSeconds: 0));
      } else {
        emit(state.copyWith(cooldownSeconds: left));
      }
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
