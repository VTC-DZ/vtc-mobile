import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/utils/countdown_format.dart';

void main() {
  test('formatMmSs pads minutes and seconds', () {
    expect(formatMmSs(0), '00:00');
    expect(formatMmSs(9), '00:09');
    expect(formatMmSs(60), '01:00');
    expect(formatMmSs(90), '01:30');
    expect(formatMmSs(600), '10:00');
    expect(formatMmSs(3599), '59:59');
  });
}
