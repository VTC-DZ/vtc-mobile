// lib/core/constants/validation_patterns.dart

abstract final class ValidationPatterns {
  ValidationPatterns._();

  /// Algerian mobile: exactly 10 digits, starts with 05, 06, or 07.
  static final RegExp dzPhone = RegExp(r'^0[567]\d{8}$');

  /// Algerian plate number regex.
  static final RegExp dzPlate = RegExp(r'^\d{5,6}[\s-]?\d{3}[\s-]?\d{2}$');

  // ── Characters a field accepts while typing (input filters) ─────────────

  /// Person names: letters of any script (Latin, Arabic, …), spaces, `'` and
  /// `-` — the characters the server's `fullName` rule `^[\p{L} '\-]{2,100}$`
  /// accepts.
  static final RegExp nameInputChars = RegExp(r"[\p{L} '\-]", unicode: true);

  /// The vehicle model: the name characters plus digits.
  static final RegExp vehicleModelInputChars =
      RegExp(r"[\p{L}0-9 '\-]", unicode: true);

  /// The driving licence number: Latin letters and digits only.
  static final RegExp licenseNumberInputChars = RegExp(r'[a-zA-Z0-9]');
}
