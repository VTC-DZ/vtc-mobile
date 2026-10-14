import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/validation_patterns.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/utils/validators.dart';
import '../../../data/auth_repository.dart';
import 'phone_state.dart';
import '../../../../../core/constants/app_strings.dart';

/// Manages state for the phone-entry screen.
///
/// Calls [AuthRepository] directly — no use case layer for the MVP.
final class PhoneCubit extends Cubit<PhoneState> {
  PhoneCubit(this._repository) : super(const PhoneState());

  final AuthRepository _repository;

  /// Called on every keystroke in the phone field.
  void phoneChanged(String value) {
    emit(
      state.copyWith(
        phoneNumber: value,
        isValid: ValidationPatterns.dzPhone.hasMatch(value),
        errorMessage: Validators.dzPhonePartial(value) ?? '',
      ),
    );
  }

  /// Requests an OTP for the E.164 form of the number and emits
  /// [PhoneStatus.success] or [PhoneStatus.failure].
  Future<void> sendOtp() async {
    if (!state.isValid) return;

    emit(state.copyWith(status: PhoneStatus.loading));

    try {
      await _repository.sendOtp(state.phoneE164);
      emit(state.copyWith(status: PhoneStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: PhoneStatus.failure,
          errorMessage: ApiException.messageOf(e,
              fallback: AppStrings.sendCodeFailed),
        ),
      );
    }
  }
}
