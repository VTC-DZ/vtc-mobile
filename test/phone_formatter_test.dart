import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/utils/phone_formatter.dart';

void main() {
  test('toE164 swaps the leading 0 for +213', () {
    expect(PhoneFormatter.toE164('0661234567'), '+213661234567');
    expect(PhoneFormatter.toE164('661234567'), '+213661234567');
  });

  test('toLocal turns +213 / 213 numbers back into 0…', () {
    expect(PhoneFormatter.toLocal('+213661234567'), '0661234567');
    expect(PhoneFormatter.toLocal('213661234567'), '0661234567');
    expect(PhoneFormatter.toLocal('0661234567'), '0661234567');
  });

  test('toDisplayFormat groups a 10-digit number as 06XX XXX XXX', () {
    expect(PhoneFormatter.toDisplayFormat('0661234567'), '0661 234 567');
    expect(PhoneFormatter.toDisplayFormat('066123'), '066123');
  });
}
