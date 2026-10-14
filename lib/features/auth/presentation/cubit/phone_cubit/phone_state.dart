import 'package:equatable/equatable.dart';

import '../../../../../core/utils/phone_formatter.dart';

/// Status lifecycle for the phone-entry screen.
enum PhoneStatus {
  initial,
  loading,
  success,
  failure,
}

/// Immutable state for [PhoneCubit].
final class PhoneState extends Equatable {
  const PhoneState({
    this.status = PhoneStatus.initial,
    this.phoneNumber = '',
    this.isValid = false,
    this.errorMessage = '',
  });

  final PhoneStatus status;

  /// Raw local number as the user typed it (e.g. "0661234567").
  final String phoneNumber;

  /// [phoneNumber] in E.164 (e.g. "+213661234567") — the format every OTP
  /// call sends.
  String get phoneE164 =>
      phoneNumber.isEmpty ? '' : PhoneFormatter.toE164(phoneNumber);

  /// True when [phoneNumber] matches the Algerian mobile regex.
  final bool isValid;

  /// Non-empty on [PhoneStatus.failure].
  final String errorMessage;

  PhoneState copyWith({
    PhoneStatus? status,
    String? phoneNumber,
    bool? isValid,
    String? errorMessage,
  }) =>
      PhoneState(
        status: status ?? this.status,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        isValid: isValid ?? this.isValid,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, phoneNumber, isValid, errorMessage];
}
