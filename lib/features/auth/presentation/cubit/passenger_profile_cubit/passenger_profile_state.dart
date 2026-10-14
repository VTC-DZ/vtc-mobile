import 'package:equatable/equatable.dart';

import '../../../../../core/models/gender.dart';

enum ProfileStatus { initial, loading, success, failure }

final class PassengerProfileState extends Equatable {
  const PassengerProfileState({
    this.fullName = '',
    this.gender,
    this.dateOfBirth,
    this.status = ProfileStatus.initial,
    this.nameError = '',
    this.errorMessage = '',
  });

  /// The name as typed; trimmed when validated and submitted.
  final String fullName;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final ProfileStatus status;
  final String nameError;
  final String errorMessage;

  /// [nameError] stays empty until the user types, so an untouched field must
  /// not count as valid.
  bool get isNameValid => fullName.trim().isNotEmpty && nameError.isEmpty;
  bool get isGenderSelected => gender != null;
  bool get isDateOfBirthSelected => dateOfBirth != null;

  bool get canSubmit =>
      isNameValid && isGenderSelected && isDateOfBirthSelected;

  PassengerProfileState copyWith({
    String? fullName,
    Gender? gender,
    DateTime? dateOfBirth,
    ProfileStatus? status,
    String? nameError,
    String? errorMessage,
  }) {
    return PassengerProfileState(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      status: status ?? this.status,
      nameError: nameError ?? this.nameError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [fullName, gender, dateOfBirth, status, nameError, errorMessage];
}
