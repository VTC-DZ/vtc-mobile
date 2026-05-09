import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/utils/validators.dart';
import '../../../../../../../features/auth/data/models/gender.dart';
import '../../../../../../../features/auth/data/models/passenger_profile_model.dart';
import '../../../../../../../features/auth/data/repo/profile_repository.dart';
import 'passenger_profile_edit_state.dart';

class PassengerProfileEditCubit extends Cubit<PassengerProfileEditState> {
  PassengerProfileEditCubit(this._repository)
      : super(const PassengerProfileEditState());

  final ProfileRepository _repository;

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  Future<void> close() {
    nameController.dispose();
    emailController.dispose();
    return super.close();
  }

  Future<void> getProfile() async {
    emit(state.copyWith(status: ProfileEditStatus.loading));
    try {
      final profile = await _repository.getProfile();
      initData(profile);
    } catch (e) {
      emit(state.copyWith(
        status: ProfileEditStatus.failure,
        errorMessage: e is String ? e : 'Failed to load profile.',
      ));
    }
  }

  void initData(PassengerProfileModel profile) {
    nameController.text = profile.fullName;
    emailController.text = profile.email ?? '';
    emit(PassengerProfileEditState(
      status: ProfileEditStatus.loaded,
      gender: profile.gender,
      dateOfBirth: profile.dateOfBirth,
      nameError: Validators.name(profile.fullName),
      emailError: Validators.email(profile.email ?? ''),
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

  void emailChanged(String value) {
    emit(state.copyWith(
      emailError: Validators.email(value.trim()),
      errorMessage: '',
    ));
  }

  Future<void> updateProfile() async {
    if (!state.canSave) return;
    emit(state.copyWith(status: ProfileEditStatus.saving, errorMessage: ''));
    try {
      final profile = await _repository.saveProfile(
        fullName: nameController.text.trim(),
        gender: state.gender!,
        dateOfBirth: state.dateOfBirth!,
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
      );
      emit(state.copyWith(
        status: ProfileEditStatus.success,
        savedProfile: profile,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileEditStatus.failure,
        errorMessage: e is String ? e : 'Failed to save profile.',
      ));
    }
  }
}
