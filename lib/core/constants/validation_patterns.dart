// lib/core/constants/validation_patterns.dart

abstract final class ValidationPatterns {
  ValidationPatterns._();

  /// Algerian mobile: exactly 10 digits, starts with 05, 06, or 07.
  static final RegExp dzPhone = RegExp(r'^0[567]\d{8}$');
}
