import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/shared/widgets/app_top_bar.dart';

void main() {
  group('badgeCountLabel', () {
    test('shows the exact count up to 10', () {
      expect(badgeCountLabel(1), '1');
      expect(badgeCountLabel(9), '9');
      expect(badgeCountLabel(10), '10');
    });

    test('caps at "+10" past 10', () {
      expect(badgeCountLabel(11), '+10');
      expect(badgeCountLabel(250), '+10');
    });
  });
}
