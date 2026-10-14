abstract final class AuthApiConstants {
  AuthApiConstants._();

  static const String base = '/api/auth';
  static const String _base = base;

  static const String otpRequest = '$_base/otp/request';
  static const String otpVerify = '$_base/otp/verify';
  static const String refresh = '$_base/refresh';
  static const String logout = '$_base/logout';
  static const String switchRole = '$_base/switch-role';
}

/// Error codes from `/api/auth/*`. The server sends these in lower case.
abstract final class AuthErrorCodes {
  AuthErrorCodes._();

  /// `401` — a wrong code, which counts toward the lock. `400` — no code to
  /// check (expired, never requested, or cleared when a lock ended), which
  /// does not.
  static const String otpInvalid = 'otp_invalid';

  /// `429` — the phone is locked after too many wrong codes. Verify and
  /// request both answer this until the lock ends.
  static const String otpLocked = 'otp_locked';
}
