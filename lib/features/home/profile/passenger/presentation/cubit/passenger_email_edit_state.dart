import 'package:equatable/equatable.dart';

enum EmailEditStatus { initial, loading, success, failure }

final class PassengerEmailEditState extends Equatable {
  const PassengerEmailEditState({
    this.status = EmailEditStatus.initial,
    this.emailError = '',
    this.errorMessage = '',
    this.email = '',
  });

  final EmailEditStatus status;
  final String emailError;
  final String errorMessage;
  final String email;

  bool get canSave => emailError.isEmpty && status != EmailEditStatus.loading;

  PassengerEmailEditState copyWith({
    EmailEditStatus? status,
    String? emailError,
    String? errorMessage,
    String? email,
  }) {
    return PassengerEmailEditState(
      status: status ?? this.status,
      emailError: emailError ?? this.emailError,
      errorMessage: errorMessage ?? this.errorMessage,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [status, emailError, errorMessage];
}
