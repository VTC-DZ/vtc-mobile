// lib/core/constants/api_constants.dart

abstract final class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.example.com/v1';

  // Auth endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';

  // Timeouts
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
}
