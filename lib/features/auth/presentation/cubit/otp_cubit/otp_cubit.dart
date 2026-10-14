import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/auth_api_constants.dart';
import '../../../data/auth_repository.dart';
import 'otp_state.dart';
import '../../../../../core/constants/app_strings.dart';

final class OtpCubit extends Cubit<OtpState> {
  OtpCubit(this._repository, {required String phoneNumber})
      : super(OtpState(phoneNumber: phoneNumber)) {
    _startResendTimer();
  }

  final AuthRepository _repository;
  Timer? _resendTimer;
  Timer? _blockTimer;
  int _failedAttempts = 0;

  void otpChanged(String value) {
    if (state.status == OtpStatus.blocked) return;
    emit(state.copyWith(otpValue: value, errorMessage: ''));
  }

  Future<void> verifyOtp() async {
    if (!state.isComplete || state.status == OtpStatus.loading) return;

    emit(state.copyWith(status: OtpStatus.loading, errorMessage: ''));

    try {
      final tokens = await _repository.verifyOtp(state.phoneNumber, state.otpValue);
      _failedAttempts = 0;

      emit(state.copyWith(
        status: OtpStatus.success,
        isNewUser: tokens.isNewUser,
        hasDriverProfile: tokens.hasDriverProfile,
      ));
    } catch (e) {
      if (e is ApiException && e.hasCode(AuthErrorCodes.otpLocked)) {
        _block(e.retryAfter);
        return;
      }
      if (_isWrongCode(e)) _failedAttempts++;
      if (_failedAttempts >= AppConstants.otpMaxFailedAttempts) {
        _block(null);
        return;
      }
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage:
            ApiException.messageOf(e, fallback: AppStrings.otpIncorrect),
      ));
    }
  }

  Future<void> resendOtp() async {
    if (!state.canResend) return;
    _resendTimer?.cancel();

    try {
      await _repository.sendOtp(state.phoneNumber);
      _failedAttempts = 0;
      emit(state.copyWith(
        resendCount: state.resendCount + 1,
        secondsRemaining: AppConstants.otpResendCooldownSecs,
        otpValue: '',
        status: OtpStatus.initial,
        errorMessage: '',
      ));
      _startResendTimer();
    } catch (e) {
      if (e is ApiException && e.hasCode(AuthErrorCodes.otpLocked)) {
        _block(e.retryAfter);
        return;
      }
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage:
            ApiException.messageOf(e, fallback: AppStrings.otpResendFailed),
      ));
    }
  }

  /// Only a code the server rejected counts toward its lock — not a timeout,
  /// a server error or an expired code (`400 otp_invalid`).
  static bool _isWrongCode(Object e) =>
      e is ApiException &&
      e.statusCode == 401 &&
      e.hasCode(AuthErrorCodes.otpInvalid);

  /// Locks the screen as the server locks the phone. The server answers the
  /// third wrong code with a plain `401` and sends no lock time, so the
  /// countdown is [AppConstants.otpBlockDurationSecs] unless [retryAfter]
  /// says otherwise.
  void _block(Duration? retryAfter) {
    _startBlockTimer();
    emit(state.copyWith(
      status: OtpStatus.blocked,
      blockSecondsRemaining:
          retryAfter?.inSeconds ?? AppConstants.otpBlockDurationSecs,
      errorMessage: '',
    ));
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsRemaining <= 0) {
        _resendTimer?.cancel();
        return;
      }
      emit(state.copyWith(secondsRemaining: state.secondsRemaining - 1));
    });
  }

  void _startBlockTimer() {
    _blockTimer?.cancel();
    _blockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.blockSecondsRemaining <= 1) {
        _blockTimer?.cancel();
        _failedAttempts = 0;
        emit(state.copyWith(
          status: OtpStatus.initial,
          blockSecondsRemaining: 0,
          otpValue: '',
          errorMessage: '',
        ));
        return;
      }
      emit(state.copyWith(
          blockSecondsRemaining: state.blockSecondsRemaining - 1));
    });
  }

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    _blockTimer?.cancel();
    return super.close();
  }
}
