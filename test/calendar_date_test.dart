import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/utils/calendar_date.dart';

void main() {
  test('toApiDate gives yyyy-MM-dd with zero padding', () {
    expect(toApiDate(DateTime(1990, 1, 5)), '1990-01-05');
    expect(toApiDate(DateTime(2030, 12, 31)), '2030-12-31');
    expect(toApiDate(DateTime(987, 3, 4)), '0987-03-04');
  });

  test('toDisplayDate gives dd/MM/yyyy', () {
    expect(toDisplayDate(DateTime(2026, 10, 3)), '03/10/2026');
    expect(toDisplayDate(DateTime(1995, 12, 25)), '25/12/1995');
  });
}
