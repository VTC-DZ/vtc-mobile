import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/utils/algerian_plate.dart';

TextEditingValue _type(String text) => AlgerianPlateFormatter()
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  group('AlgerianPlateFormatter', () {
    test('inserts the hyphens as the digits arrive', () {
      expect(_type('12345').text, '12345');
      expect(_type('123451').text, '12345-1');
      expect(_type('12345123').text, '12345-123');
      expect(_type('123451231').text, '12345-123-1');
      expect(_type('1234512316').text, '12345-123-16');
    });

    test('drops non-digits and caps the plate at 10 digits', () {
      expect(_type('12a34-5 12x3').text, '12345-123');
      expect(_type('123451231699').text, '12345-123-16');
    });

    test('keeps the caret at the end', () {
      final value = _type('1234512316');
      expect(value.selection, const TextSelection.collapsed(offset: 12));
    });
  });

  test('toWire sends the plate with spaces', () {
    expect(AlgerianPlate.toWire('12345-123-16'), '12345 123 16');
    expect(AlgerianPlate.toWire(' 12345-123-16 '), '12345 123 16');
  });
}
