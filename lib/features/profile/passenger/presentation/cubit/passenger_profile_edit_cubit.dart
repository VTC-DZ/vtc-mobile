import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/utils/validators.dart';
import '../../../../../../features/auth/data/models/gender.dart';
import '../../../../../../features/auth/data/models/passenger_profile_model.dart';
import '../../../../../../features/auth/data/repo/profile_repository.dart';
import 'passenger_profile_edit_state.dart';

class PassengerProfileEditCubit extends Cubit<PassengerProfileEditState> {
  PassengerProfileEditCubit(this._repository)
      : super(const PassengerProfileEditState());

  final ProfileRepository _repository;

  final nameController = TextEditingController();

  @override
  Future<void> close() {
    nameController.dispose();
    return super.close();
  }

  void initData(PassengerProfileModel profile) {
    nameController.text = profile.fullName;
    emit(PassengerProfileEditState(
      getProfileStatus: GetProfileStatus.success,
      gender: profile.gender,
      dateOfBirth: profile.dateOfBirth,
      email: profile.email,
      nameError: Validators.name(profile.fullName),
    ));
  }

  void nameChanged(String value) {
    emit(state.copyWith(
      nameError: Validators.name(value.trim()),
      errorMessage: '',
    ));
  }

  void genderChanged(Gender gender) {
    emit(state.copyWith(gender: gender, errorMessage: ''));
  }

  void dateOfBirthChanged(DateTime date) {
    emit(state.copyWith(dateOfBirth: date, errorMessage: ''));
  }

  Future<void> updateProfile() async {
    if (!state.canSave) return;
    emit(state.copyWith(updateProfileStatus: UpdateProfileStatus.loading, errorMessage: ''));
    try {
      final profile = await _repository.saveProfile(
        fullName: nameController.text.trim(),
        gender: state.gender!,
        dateOfBirth: state.dateOfBirth!,
      );
      emit(state.copyWith(
        updateProfileStatus: UpdateProfileStatus.success,
        savedProfile: profile,
      ));
    } catch (e) {
      emit(state.copyWith(
        updateProfileStatus: UpdateProfileStatus.failure,
        errorMessage: e is String ? e : 'Failed to save profile.',
      ));
    }
  }
}
