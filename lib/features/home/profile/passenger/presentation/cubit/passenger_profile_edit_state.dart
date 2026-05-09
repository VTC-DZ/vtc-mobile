import 'package:equatable/equatable.dart';

import '../../../../../../../features/auth/data/models/gender.dart';
import '../../../../../../../features/auth/data/models/passenger_profile_model.dart';

enum ProfileEditStatus { loading, loaded, saving, success, failure }

final class PassengerProfileEditState extends Equatable {
  const PassengerProfileEditState({
    this.status = ProfileEditStatus.loading,
    this.gender,
    this.dateOfBirth,
    this.email,
    this.nameError = '',
    this.errorMessage = '',
    this.savedProfile,
  });

  final ProfileEditStatus status;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? email;
  final String nameError;
  final String errorMessage;
  final PassengerProfileModel? savedProfile;

  bool get canSave =>
      nameError.isEmpty &&
      gender != null &&
      dateOfBirth != null &&
      status != ProfileEditStatus.saving;

  PassengerProfileEditState copyWith({
    ProfileEditStatus? status,
    Gender? gender,
    DateTime? dateOfBirth,
    String? email,
    String? nameError,
    String? errorMessage,
    PassengerProfileModel? savedProfile,
  }) {
    return PassengerProfileEditState(
      status: status ?? this.status,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      nameError: nameError ?? this.nameError,
      errorMessage: errorMessage ?? this.errorMessage,
      savedProfile: savedProfile ?? this.savedProfile,
    );
  }

  @override
  List<Object?> get props => [
        status,
        gender,
        dateOfBirth,
        email,
        nameError,
        errorMessage,
        savedProfile,
      ];
}
