import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

enum PhoneEditStep { phoneEntry, otpVerification }
enum PhoneEditStatus { initial, loading, success, failure, blocked }

final class PhoneEditState extends Equatable {
  const PhoneEditState({
    this.step = PhoneEditStep.phoneEntry,
    this.status = PhoneEditStatus.initial,
    this.newPhone = '',
    this.phoneError = '',
    this.errorMessage = '',
    this.otpValue = '',
    this.secondsRemaining = AppConstants.otpResendCooldownSecs,
    this.resendCount = 0,
    this.blockSecondsRemaining = 0,
  });

  final PhoneEditStep step;
  final PhoneEditStatus status;
  final String newPhone;
  final String phoneError;
  final String errorMessage;
  final String otpValue;
  final int secondsRemaining;
  final int resendCount;
  final int blockSecondsRemaining;

  bool get canRequestOtp =>
      newPhone.length == AppConstants.phoneMaxLength &&
      phoneError.isEmpty &&
      status != PhoneEditStatus.loading;

  bool get isOtpComplete => otpValue.length == AppConstants.otpLength;
  bool get canResend =>
      secondsRemaining == 0 &&
      resendCount < AppConstants.otpMaxResendCount &&
      blockSecondsRemaining == 0;

  String get lastFourDigits => newPhone.length >= 4
      ? newPhone.substring(newPhone.length - 4)
      : newPhone;

  PhoneEditState copyWith({
    PhoneEditStep? step,
    PhoneEditStatus? status,
    String? newPhone,
    String? phoneError = '',
    String? errorMessage,
    String? otpValue,
    int? secondsRemaining,
    int? resendCount,
    int? blockSecondsRemaining,
  }) =>
      PhoneEditState(
        step: step ?? this.step,
        status: status ?? this.status,
        newPhone: newPhone ?? this.newPhone,
        phoneError: phoneError ?? this.phoneError,
        errorMessage: errorMessage ?? this.errorMessage,
        otpValue: otpValue ?? this.otpValue,
        secondsRemaining: secondsRemaining ?? this.secondsRemaining,
        resendCount: resendCount ?? this.resendCount,
        blockSecondsRemaining:
            blockSecondsRemaining ?? this.blockSecondsRemaining,
      );

  @override
  List<Object?> get props => [
        step,
        status,
        newPhone,
        phoneError,
        errorMessage,
        otpValue,
        secondsRemaining,
        resendCount,
        blockSecondsRemaining,
      ];
}
