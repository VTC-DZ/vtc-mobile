import 'package:flutter/services.dart';

/// Algerian licence plates: typed and shown as `NNNNN-NNN-NN`, sent to the
/// API with spaces instead (`NNNNN NNN NN`).
abstract final class AlgerianPlate {
  AlgerianPlate._();

  /// The API form of a typed plate: `12345-123-12` → `12345 123 12`.
  static String toWire(String plate) => plate.replaceAll('-', ' ').trim();
}

/// Formats input as NNNNN-NNN-NN, inserting hyphens automatically.
/// Only digits are accepted; the formatter limits to 10 digits total.
class AlgerianPlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 10 ? digits.substring(0, 10) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < capped.length; i++) {
      if (i == 5 || i == 8) buffer.write('-');
      buffer.write(capped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
