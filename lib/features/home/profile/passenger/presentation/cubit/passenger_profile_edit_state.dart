import 'package:equatable/equatable.dart';

import '../../../../../../../features/auth/data/models/gender.dart';
import '../../../../../../../features/auth/data/models/passenger_profile_model.dart';

enum ProfileEditStatus { loading, loaded, saving, success, failure }

final class PassengerProfileEditState extends Equatable {
  const PassengerProfileEditState({
    this.status = ProfileEditStatus.loading,
    this.gender,
    this.dateOfBirth,
    this.nameError = '',
    this.emailError = '',
    this.errorMessage = '',
    this.savedProfile,
  });

  final ProfileEditStatus status;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String nameError;
  final String emailError;
  final String errorMessage;
  final PassengerProfileModel? savedProfile;

  bool get canSave =>
      nameError.isEmpty &&
      emailError.isEmpty &&
      gender != null &&
      dateOfBirth != null &&
      status != ProfileEditStatus.saving;

  PassengerProfileEditState copyWith({
    ProfileEditStatus? status,
    Gender? gender,
    DateTime? dateOfBirth,
    String? nameError,
    String? emailError,
    String? errorMessage,
    PassengerProfileModel? savedProfile,
  }) {
    return PassengerProfileEditState(
      status: status ?? this.status,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nameError: nameError ?? this.nameError,
      emailError: emailError ?? this.emailError,
      errorMessage: errorMessage ?? this.errorMessage,
      savedProfile: savedProfile ?? this.savedProfile,
    );
  }

  @override
  List<Object?> get props => [
        status,
        gender,
        dateOfBirth,
        nameError,
        emailError,
        errorMessage,
        savedProfile,
      ];
}
