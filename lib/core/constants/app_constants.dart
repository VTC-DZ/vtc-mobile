// lib/core/constants/app_constants.dart

abstract final class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Rapidoo';

  // Algeria phone
  static const String countryCode = '+213';
  static const int phoneMaxLength = 10;
  static const String phonePrefix = '0';
  static const String phoneHint = '06XX XXX XXX';

  // OTP. The server sends none of these values, so the app mirrors the
  // backend's (`vtc.otp.*`, `RateLimitConfig`) and user story AUTH-002.
  static const int otpLength = 6; // vtc.otp.code-length
  static const int otpResendCooldownSecs = 60; // 1 request refilled per 60 s
  static const int otpBlockDurationSecs = 600; // vtc.otp.lock-duration
  static const int otpMaxResendCount = 3; // AUTH-002; the server has no cap
  static const int otpMaxFailedAttempts = 3; // vtc.otp.max-attempts

  // Design system — reference size (used by ScreenUtil)
  static const double designWidth = 375.0;
  static const double designHeight = 812.0;

  // Driver registration — document uploads
  static const int maxDocumentSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int vehicleYearFirst = 2000;
  static const int driverMinAgeYears = 18;
}
