// lib/core/utils/validators.dart

import '../constants/validation_patterns.dart';

/// Stateless validator helpers used in form fields and cubits.
abstract final class Validators {
  Validators._();

  /// Returns `null` if [value] is a valid Algerian mobile number,
  /// otherwise returns an error message string.
  static String? dzPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number.';
    }
    if (!ValidationPatterns.dzPhone.hasMatch(value)) {
      return 'Enter a valid Algerian number (05/06/07 followed by 8 digits).';
    }
    return null;
  }
}
