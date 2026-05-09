import 'package:equatable/equatable.dart';

enum EmailEditStatus { idle, saving, success, failure }

final class PassengerEmailEditState extends Equatable {
  const PassengerEmailEditState({
    this.status = EmailEditStatus.idle,
    this.emailError = '',
    this.errorMessage = '',
  });

  final EmailEditStatus status;
  final String emailError;
  final String errorMessage;

  bool get canSave =>
      emailError.isEmpty && status != EmailEditStatus.saving;

  PassengerEmailEditState copyWith({
    EmailEditStatus? status,
    String? emailError,
    String? errorMessage,
  }) {
    return PassengerEmailEditState(
      status: status ?? this.status,
      emailError: emailError ?? this.emailError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, emailError, errorMessage];
}
