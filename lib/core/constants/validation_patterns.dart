// lib/core/constants/validation_patterns.dart

abstract final class ValidationPatterns {
  ValidationPatterns._();

  /// Algerian mobile: exactly 10 digits, starts with 05, 06, or 07.
  static final RegExp dzPhone = RegExp(r'^0[567]\d{8}$');

  /// Algerian plate number regex.
  static final RegExp dzPlate = RegExp(r'^\d{5,6}[\s-]?\d{3}[\s-]?\d{2}$');
}
