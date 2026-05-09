import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khfif_drif/features/auth/data/models/passenger_profile_model.dart';

import '../../../../../features/auth/data/repo/profile_repository.dart';
import 'passenger_home_state.dart';

class PassengerHomeCubit extends Cubit<PassengerHomeState> {
  PassengerHomeCubit(this._repository) : super(const PassengerHomeState());

  final ProfileRepository _repository;

  Future<void> getProfile() async {
    emit(state.copyWith(status: PassengerHomeStatus.loading));
    try {
      final PassengerProfileModel profile = await _repository.getProfile();
      emit(
          state.copyWith(status: PassengerHomeStatus.loaded, profile: profile));
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

  void updateEmail(String email) {
    emit(state.copyWith(
      profile: state.profile!.copyWith(email: email),
    ));
  }
}
