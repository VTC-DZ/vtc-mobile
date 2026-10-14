import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/models/gender.dart';
import '../../../../profile/shared/data/profile_repository.dart';
import 'passenger_profile_state.dart';
import '../../../../../core/constants/app_strings.dart';

final class PassengerProfileCubit extends Cubit<PassengerProfileState> {
  PassengerProfileCubit(this._repository)
      : super(const PassengerProfileState());

  final ProfileRepository _repository;

  void nameChanged(String value) {
    emit(state.copyWith(
      fullName: value,
      nameError: Validators.name(value.trim()),
    ));
  }

  void genderChanged(Gender gender) {
    emit(state.copyWith(gender: gender));
  }

  void dateOfBirthChanged(DateTime date) {
    emit(state.copyWith(dateOfBirth: date));
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;

    emit(state.copyWith(status: ProfileStatus.loading, errorMessage: ''));

    try {
      await _repository.saveProfile(
        fullName: state.fullName.trim(),
        gender: state.gender!,
        dateOfBirth: state.dateOfBirth!,
      );
      emit(state.copyWith(status: ProfileStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage:
            ApiException.messageOf(e, fallback: AppStrings.genericError),
      ));
    }
  }
}
