// lib/core/constants/passenger_api_constants.dart

abstract final class PassengerApiConstants {
  PassengerApiConstants._();

  static const String _base = '/api/passenger';

  // Auth
  static const String otpRequest = '$_base/auth/otp/request';
  static const String otpVerify = '$_base/auth/otp/verify';
  static const String refresh = '$_base/auth/refresh';
  static const String logout = '$_base/auth/logout';
  static const String switchRole = '$_base/auth/switch-role';

  // Profile
  static const String profile = '$_base/profile';
  static const String updateEmail = '$_base/email';
}
