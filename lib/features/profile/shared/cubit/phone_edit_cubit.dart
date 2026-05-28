import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../features/auth/data/repo/profile_repository.dart';
import 'phone_edit_state.dart';

class PhoneEditCubit extends Cubit<PhoneEditState> {
  PhoneEditCubit(this._repository, {required String currentPhone})
      : super(const PhoneEditState()) {
    phoneController.text = PhoneFormatter.toLocal(currentPhone);
  }

  final ProfileRepository _repository;
  final phoneController = TextEditingController();
  Timer? _resendTimer;
  Timer? _blockTimer;
  int _failedAttempts = 0;

  void phoneChanged(String value) {
    final error = Validators.dzPhonePartial(value);
    final fullError = value.length == AppConstants.phoneMaxLength
        ? Validators.dzPhone(value)
        : null;
    emit(state.copyWith(
      newPhone: value,
      phoneError: error ?? fullError ?? '',
      errorMessage: '',
    ));
  }

  Future<void> requestPhoneChange() async {
    if (!state.canRequestOtp) return;
    emit(state.copyWith(status: PhoneEditStatus.loading, errorMessage: ''));
    try {
      final expiresIn = await _repository.requestPhoneChange(
        newPhone: PhoneFormatter.toE164(state.newPhone),
      );
      emit(state.copyWith(
        status: PhoneEditStatus.initial,
        step: PhoneEditStep.otpVerification,
        secondsRemaining: expiresIn,
        otpValue: '',
        errorMessage: '',
      ));
      _startResendTimer();
    } catch (e) {
      emit(state.copyWith(
        status: PhoneEditStatus.failure,
        errorMessage: e is String ? e : 'Failed to send code.',
      ));
    }
  }

  void otpChanged(String value) {
    if (state.status == PhoneEditStatus.blocked) return;
    emit(state.copyWith(otpValue: value, errorMessage: ''));
  }

  Future<void> confirmPhoneChange() async {
    if (!state.isOtpComplete || state.status == PhoneEditStatus.loading) return;
    emit(state.copyWith(status: PhoneEditStatus.loading, errorMessage: ''));
    try {
      await _repository.confirmPhoneChange(
        newPhone: PhoneFormatter.toE164(state.newPhone),
        code: state.otpValue,
      );
      _failedAttempts = 0;
      _resendTimer?.cancel();
      _blockTimer?.cancel();
      emit(state.copyWith(status: PhoneEditStatus.success));
    } catch (e) {
      _failedAttempts++;
      if (_failedAttempts >= AppConstants.otpMaxFailedAttempts) {
        _startBlockTimer();
        emit(state.copyWith(
          status: PhoneEditStatus.blocked,
          blockSecondsRemaining: AppConstants.otpBlockDurationSecs,
          errorMessage: '',
        ));
      } else {
        emit(state.copyWith(
          status: PhoneEditStatus.failure,
          errorMessage: e is String ? e : 'Incorrect code, try again',
        ));
      }
    }
  }

  Future<void> resendOtp() async {
    if (!state.canResend) return;
    _resendTimer?.cancel();
    try {
      final expiresIn = await _repository.requestPhoneChange(
        newPhone: PhoneFormatter.toE164(state.newPhone),
      );
      _failedAttempts = 0;
      emit(state.copyWith(
        resendCount: state.resendCount + 1,
        secondsRemaining: expiresIn,
        otpValue: '',
        status: PhoneEditStatus.initial,
        errorMessage: '',
      ));
      _startResendTimer();
    } catch (e) {
      emit(state.copyWith(
        status: PhoneEditStatus.failure,
        errorMessage: e is String ? e : 'Could not resend code.',
      ));
    }
  }

  void goBackToPhoneEntry() {
    _resendTimer?.cancel();
    _blockTimer?.cancel();
    emit(state.copyWith(
      step: PhoneEditStep.phoneEntry,
      status: PhoneEditStatus.initial,
      otpValue: '',
      secondsRemaining: AppConstants.otpResendCooldownSecs,
      resendCount: 0,
      blockSecondsRemaining: 0,
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
          status: PhoneEditStatus.initial,
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
    phoneController.dispose();
    return super.close();
  }
}
