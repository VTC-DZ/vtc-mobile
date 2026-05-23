abstract final class AuthApiConstants {
  AuthApiConstants._();

  static const String _base = '/api/auth';

  static const String otpRequest = '$_base/otp/request';
  static const String otpVerify = '$_base/otp/verify';
  static const String refresh = '$_base/refresh';
  static const String logout = '$_base/logout';
  static const String switchRole = '$_base/switch-role';
}
