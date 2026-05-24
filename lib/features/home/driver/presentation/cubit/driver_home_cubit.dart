import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../features/auth/data/repo/driver_repository.dart';
import '../../../../../features/auth/data/models/driver_profile_model.dart';
import 'driver_home_state.dart';

class DriverHomeCubit extends Cubit<DriverHomeState> {
  DriverHomeCubit(this._repository) : super(const DriverHomeState());

  final DriverRepository _repository;

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
}
