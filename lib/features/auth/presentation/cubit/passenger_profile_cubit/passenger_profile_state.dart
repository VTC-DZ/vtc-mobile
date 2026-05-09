import 'package:equatable/equatable.dart';

import '../../../data/models/gender.dart';

enum ProfileStatus { initial, loading, success, failure }

final class PassengerProfileState extends Equatable {
  final Gender? gender;
  final DateTime? dateOfBirth;
  final ProfileStatus status;
  final String nameError;
  final String emailError;
  final String errorMessage;

  const PassengerProfileState({
    this.gender,
    this.dateOfBirth,
    this.status = ProfileStatus.initial,
    this.nameError = '',
    this.emailError = '',
    this.errorMessage = '',
  });

  bool get isGenderSelected => gender != null;
  bool get isDateOfBirthSelected => dateOfBirth != null;

  bool get canSubmit =>
      nameError.isEmpty &&
      emailError.isEmpty &&
      isGenderSelected &&
      isDateOfBirthSelected &&
      status != ProfileStatus.loading;

  PassengerProfileState copyWith({
    Gender? gender,
    DateTime? dateOfBirth,
    ProfileStatus? status,
    String? nameError,
    String? emailError,
    String? errorMessage,
  }) {
    return PassengerProfileState(
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      status: status ?? this.status,
      nameError: nameError ?? this.nameError,
      emailError: emailError ?? this.emailError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [gender, dateOfBirth, status, nameError, emailError, errorMessage];
}
