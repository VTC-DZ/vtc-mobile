import 'package:equatable/equatable.dart';

import '../../../../../../features/auth/data/models/gender.dart';
import '../../../../../../features/auth/data/models/passenger_profile_model.dart';

enum GetProfileStatus { initial, loading, success, failure }
enum UpdateProfileStatus { initial, loading, success, failure }

final class PassengerProfileEditState extends Equatable {
  const PassengerProfileEditState({
    this.getProfileStatus = GetProfileStatus.initial,
    this.updateProfileStatus = UpdateProfileStatus.initial,
    this.gender,
    this.dateOfBirth,
    this.email,
    this.phone,
    this.nameError = '',
    this.errorMessage = '',
    this.savedProfile,
  });

  final GetProfileStatus getProfileStatus;
  final UpdateProfileStatus updateProfileStatus;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? email;
  final String? phone;
  final String nameError;
  final String errorMessage;
  final PassengerProfileModel? savedProfile;

  bool get canSave =>
      nameError.isEmpty &&
      gender != null &&
      dateOfBirth != null &&
      updateProfileStatus != UpdateProfileStatus.loading;

  PassengerProfileEditState copyWith({
    GetProfileStatus? getProfileStatus,
    UpdateProfileStatus? updateProfileStatus,
    Gender? gender,
    DateTime? dateOfBirth,
    String? email,
    String? phone,
    String? nameError,
    String? errorMessage,
    PassengerProfileModel? savedProfile,
  }) {
    return PassengerProfileEditState(
      getProfileStatus: getProfileStatus ?? this.getProfileStatus,
      updateProfileStatus: updateProfileStatus ?? this.updateProfileStatus,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nameError: nameError ?? this.nameError,
      errorMessage: errorMessage ?? this.errorMessage,
      savedProfile: savedProfile ?? this.savedProfile,
    );
  }

  @override
  List<Object?> get props => [
        getProfileStatus,
        updateProfileStatus,
        gender,
        dateOfBirth,
        email,
        phone,
        nameError,
        errorMessage,
        savedProfile,
      ];
}
