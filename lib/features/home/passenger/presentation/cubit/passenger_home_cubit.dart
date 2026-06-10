import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khfif_drif/core/session/auth_session.dart';
import 'package:khfif_drif/features/auth/data/models/passenger_profile_model.dart';

import '../../../../../features/auth/data/repo/profile_repository.dart';
import '../../../../../features/ride/data/ride_repository.dart';
import 'passenger_home_state.dart';

class PassengerHomeCubit extends Cubit<PassengerHomeState> {
  PassengerHomeCubit(
    this._repository, [
    this._rideRepository = const RideRepository(),
  ]) : super(const PassengerHomeState());

  final ProfileRepository _repository;
  final RideRepository _rideRepository;

  Future<void> getProfile() async {
    emit(state.copyWith(status: PassengerHomeStatus.loading));
    try {
      final PassengerProfileModel profile = await _repository.getProfile();
      if (profile.hasDriverProfile && !AuthSession.hasDriverProfile) {
        await AuthSession.setHasDriverProfile(true);
      }
      emit(state.copyWith(
          status: PassengerHomeStatus.success, profile: profile));
    } catch (e) {
      emit(state.copyWith(
        status: PassengerHomeStatus.failure,
        errorMessage: e is String ? e : 'Failed to load profile.',
      ));
    }
  }

  void updateProfile(PassengerProfileModel profile) {
    emit(state.copyWith(profile: profile));
  }

  void updateSelectedIndex(int index) {
    emit(state.copyWith(selectedIndex: index));
  }

  void updateEmail(String email) {
    emit(state.copyWith(
      profile: state.profile!.copyWith(email: email),
    ));
  }

  void updatePhone(String phone) {
    emit(state.copyWith(
      profile: state.profile!.copyWith(phone: phone),
    ));
  }

  Future<void> checkActiveRide() async {
    emit(state.copyWith(activeRideStatus: ActiveRideStatus.loading));
    try {
      final result = await _rideRepository.getActiveRide();

      if (result.request != null &&
          (result.request!.state == 'REQUESTED' ||
              result.request!.state == 'NEGOTIATING')) {
        emit(state.copyWith(
          activeRideStatus: ActiveRideStatus.foundRequest,
          activeRequest: result.request,
        ));
        return;
      }

      if (result.ride != null &&
          result.ride!.state != 'COMPLETED' &&
          result.ride!.state != 'CANCELLED') {
        emit(state.copyWith(
          activeRideStatus: ActiveRideStatus.foundRide,
          activeRide: result.ride,
        ));
        return;
      }

      emit(state.copyWith(activeRideStatus: ActiveRideStatus.none));
    } catch (_) {
      emit(state.copyWith(activeRideStatus: ActiveRideStatus.none));
    }
  }

  void clearActiveRideStatus() {
    emit(state.copyWith(activeRideStatus: ActiveRideStatus.idle));
  }
}
