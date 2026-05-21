import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/validators.dart';
import '../../../data/models/gender.dart';
import '../../../data/repo/profile_repository.dart';
import 'passenger_profile_state.dart';

final class PassengerProfileCubit extends Cubit<PassengerProfileState> {
  PassengerProfileCubit(this._repository)
      : super(const PassengerProfileState());

  final ProfileRepository _repository;

  void nameChanged(String value) {
    emit(state.copyWith(nameError: Validators.name(value.trim())));
  }

  void genderChanged(Gender gender) {
    emit(state.copyWith(gender: gender));
  }

  void dateOfBirthChanged(DateTime date) {
    emit(state.copyWith(dateOfBirth: date));
  }

  void emailChanged(String value) {
    emit(state.copyWith(emailError: Validators.email(value.trim())));
  }

  Future<void> submit({required String fullName}) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(status: ProfileStatus.loading, errorMessage: ''));

    try {
      await _repository.saveProfile(
        fullName: fullName.trim(),
        gender: state.gender!,
        dateOfBirth: state.dateOfBirth!,
      );
      emit(state.copyWith(status: ProfileStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage:
            e is String ? e : 'Something went wrong. Please try again.',
      ));
    }
  }
}
