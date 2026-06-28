import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/session/auth_session.dart';
import '../../../../../features/auth/data/models/driver_profile_model.dart';
import '../../../../../features/auth/data/repo/driver_repository.dart';
import '../../../../../features/ride/driver/data/driver_ride_repository.dart';
import '../../../../../features/ride/driver/data/models/driver_ride_models.dart';
import 'driver_home_state.dart';

class DriverHomeCubit extends Cubit<DriverHomeState> {
  DriverHomeCubit(
    this._repository, [
    this._rideRepository = const DriverRideRepository(),
  ]) : super(const DriverHomeState()) {
    unawaited(AuthSession.setLastRole(AuthSession.roleDriver));
  }

  final DriverRepository _repository;
  final DriverRideRepository _rideRepository;

  Future<void> getProfile() async {
    emit(state.copyWith(status: DriverHomeStatus.loading));
    try {
      final DriverProfileModel profile = await _repository.getDriverProfile();
      emit(state.copyWith(status: DriverHomeStatus.success, profile: profile));
    } catch (e) {
      emit(state.copyWith(
        status: DriverHomeStatus.failure,
        errorMessage: e is String ? e : 'Failed to load profile.',
      ));
    }
  }

  void updateProfile(DriverProfileModel profile) {
    emit(state.copyWith(profile: profile));
  }

  void updateSelectedIndex(int index) {
    emit(state.copyWith(selectedIndex: index));
  }

  void updateEmail(String email) {
    if (state.profile == null) return;
    emit(state.copyWith(
      profile: state.profile!.copyWith(email: email),
    ));
  }

  void updatePhone(String phone) {
    if (state.profile == null) return;
    emit(state.copyWith(
      profile: state.profile!.copyWith(phone: phone),
    ));
  }

  Future<void> checkActiveRide() async {
    emit(state.copyWith(
        activeRideCheckStatus: DriverActiveRideCheckStatus.loading));
    try {
      final ride = await _rideRepository.getActiveRide();
      if (ride != null &&
          ride.state != ActiveDriverRideState.completed &&
          ride.state != ActiveDriverRideState.cancelled) {
        emit(state.copyWith(
            activeRideCheckStatus: DriverActiveRideCheckStatus.found));
      } else {
        emit(state.copyWith(
            activeRideCheckStatus: DriverActiveRideCheckStatus.none));
      }
    } catch (_) {
      emit(state.copyWith(
          activeRideCheckStatus: DriverActiveRideCheckStatus.none));
    }
  }

  void clearActiveRideCheckStatus() {
    emit(state.copyWith(
        activeRideCheckStatus: DriverActiveRideCheckStatus.idle));
  }
}
