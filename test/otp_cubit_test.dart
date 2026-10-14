import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/constants/app_constants.dart';
import 'package:rapidoo/core/constants/auth_api_constants.dart';
import 'package:rapidoo/core/errors/api_exception.dart';
import 'package:rapidoo/core/models/auth_tokens_model.dart';
import 'package:rapidoo/features/auth/data/auth_repository.dart';
import 'package:rapidoo/features/auth/presentation/cubit/otp_cubit/otp_cubit.dart';
import 'package:rapidoo/features/auth/presentation/cubit/otp_cubit/otp_state.dart';

/// Records verify and resend calls; verify fails while [verifyError] is set.
class _FakeAuthRepository extends AuthRepository {
  final verifyCalls = <({String phone, String code})>[];
  final sendCalls = <String>[];
  Object? verifyError;
  AuthTokensModel tokens =
      const AuthTokensModel(accessToken: 'access', refreshToken: 'refresh');

  @override
  Future<AuthTokensModel> verifyOtp(String phoneE164, String otp) async {
    verifyCalls.add((phone: phoneE164, code: otp));
    final error = verifyError;
    if (error != null) throw error;
    return tokens;
  }

  @override
  Future<void> sendOtp(String phoneE164) async => sendCalls.add(phoneE164);
}

/// What the server answers for a wrong code: `401 otp_invalid`.
const _wrongCode = ApiException(
  message: 'Code incorrect',
  code: AuthErrorCodes.otpInvalid,
  statusCode: 401,
);

void main() {
  const phone = '+213661234567';
  late _FakeAuthRepository repository;
  late OtpCubit cubit;

  setUp(() {
    repository = _FakeAuthRepository();
    cubit = OtpCubit(repository, phoneNumber: phone);
  });
  // The cubit runs a resend countdown from creation; closing cancels it.
  tearDown(() => cubit.close());

  test('does not verify an incomplete code', () async {
    cubit.otpChanged('123');
    await cubit.verifyOtp();

    expect(repository.verifyCalls, isEmpty);
  });

  test('verifies the E.164 number with the typed code', () async {
    repository.tokens = const AuthTokensModel(
      accessToken: 'access',
      refreshToken: 'refresh',
      isNewUser: true,
      hasDriverProfile: true,
    );
    cubit.otpChanged('123456');

    await cubit.verifyOtp();

    expect(repository.verifyCalls.single, (phone: phone, code: '123456'));
    expect(cubit.state.status, OtpStatus.success);
    expect(cubit.state.isNewUser, isTrue);
    expect(cubit.state.hasDriverProfile, isTrue);
  });

  test('a wrong code shows the server message', () async {
    repository.verifyError = _wrongCode;
    cubit.otpChanged('000000');

    await cubit.verifyOtp();

    expect(cubit.state.status, OtpStatus.failure);
    expect(cubit.state.errorMessage, 'Code incorrect');
  });

  test('locks after the maximum number of wrong codes', () async {
    repository.verifyError = _wrongCode;
    cubit.otpChanged('000000');

    for (var i = 0; i < AppConstants.otpMaxFailedAttempts; i++) {
      await cubit.verifyOtp();
    }

    expect(cubit.state.status, OtpStatus.blocked);
    expect(cubit.state.blockSecondsRemaining, AppConstants.otpBlockDurationSecs);

    cubit.otpChanged('123456');
    expect(cubit.state.otpValue, '000000',
        reason: 'typing is ignored while blocked');
  });

  test('timeouts and expired codes do not count toward the lock', () async {
    cubit.otpChanged('000000');
    repository.verifyError =
        const ApiException(message: 'Request timed out.');
    for (var i = 0; i < AppConstants.otpMaxFailedAttempts; i++) {
      await cubit.verifyOtp();
    }
    repository.verifyError = const ApiException(
      message: 'Code expiré',
      code: AuthErrorCodes.otpInvalid,
      statusCode: 400,
    );
    await cubit.verifyOtp();

    expect(cubit.state.status, OtpStatus.failure);
    expect(cubit.state.errorMessage, 'Code expiré');
  });

  test('blocks at once when the server says the phone is locked', () async {
    repository.verifyError = const ApiException(
      message: 'Compte bloqué',
      code: AuthErrorCodes.otpLocked,
      statusCode: 429,
    );
    cubit.otpChanged('000000');

    await cubit.verifyOtp();

    expect(cubit.state.status, OtpStatus.blocked);
    expect(cubit.state.blockSecondsRemaining, AppConstants.otpBlockDurationSecs);
  });

  test('counts the lock down from Retry-After when the server sends one',
      () async {
    repository.verifyError = const ApiException(
      message: 'Compte bloqué',
      code: AuthErrorCodes.otpLocked,
      statusCode: 429,
      retryAfter: Duration(seconds: 90),
    );
    cubit.otpChanged('000000');

    await cubit.verifyOtp();

    expect(cubit.state.status, OtpStatus.blocked);
    expect(cubit.state.blockSecondsRemaining, 90);
  });

  test('cannot resend before the cooldown has run out', () async {
    expect(cubit.state.canResend, isFalse);

    await cubit.resendOtp();

    expect(repository.sendCalls, isEmpty);
  });
}
