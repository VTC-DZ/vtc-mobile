// lib/core/constants/driver_api_constants.dart

abstract final class DriverApiConstants {
  DriverApiConstants._();

  static const String _base = '/api/driver';

  // Auth
  // static const String otpRequest = '$_base/auth/otp/request'; //! use passenger otp request
  // static const String otpVerify = '$_base/auth/otp/verify';  //! use passenger otp verify
  static const String refresh = '$_base/auth/refresh'; //! use passenger refresh
  static const String logout = '$_base/auth/logout'; //! use passenger logout

  // Registration
  static const String registration = '$_base/registration';

  // Profile
  static const String profile = '$_base/profile';
}
