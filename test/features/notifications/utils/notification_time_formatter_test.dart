import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/features/notifications/utils/notification_time_formatter.dart';

void main() {
  // Offset-less ISO strings parse as local time, so these are deterministic
  // on any machine.
  final now = DateTime(2026, 10, 12, 15);
  String at(DateTime local) => local.toIso8601String();
  String ago(Duration elapsed) => at(now.subtract(elapsed));

  group('formatNotificationTime', () {
    test('under a minute is "Just now"', () {
      expect(
        formatNotificationTime(ago(const Duration(seconds: 30)), now: now),
        'Just now',
      );
    });

    test('a timestamp ahead of the phone clock is "Just now"', () {
      expect(
        formatNotificationTime(
          at(now.add(const Duration(minutes: 2))),
          now: now,
        ),
        'Just now',
      );
    });

    test('under an hour counts minutes', () {
      expect(
        formatNotificationTime(ago(const Duration(minutes: 5)), now: now),
        '5 min ago',
      );
      expect(
        formatNotificationTime(
          ago(const Duration(minutes: 59, seconds: 59)),
          now: now,
        ),
        '59 min ago',
      );
    });

    test('under a day counts hours', () {
      expect(
        formatNotificationTime(ago(const Duration(hours: 1)), now: now),
        '1 h ago',
      );
      expect(
        formatNotificationTime(
          ago(const Duration(hours: 23, minutes: 59)),
          now: now,
        ),
        '23 h ago',
      );
    });

    test('hours win over "Yesterday" across midnight', () {
      expect(
        formatNotificationTime(
          at(DateTime(2026, 10, 11, 23)),
          now: DateTime(2026, 10, 12, 1),
        ),
        '2 h ago',
      );
    });

    test('a day or more old on the previous calendar day is "Yesterday"', () {
      expect(
        formatNotificationTime(at(DateTime(2026, 10, 11, 9)), now: now),
        'Yesterday',
      );
    });

    test('"Yesterday" across a month boundary', () {
      expect(
        formatNotificationTime(
          at(DateTime(2026, 10, 31, 8)),
          now: DateTime(2026, 11, 1, 10),
        ),
        'Yesterday',
      );
    });

    test('older items show the date as dd/MM/yyyy', () {
      expect(
        formatNotificationTime(at(DateTime(2026, 10, 10, 15)), now: now),
        '10/10/2026',
      );
    });

    test('a UTC timestamp is measured against local time', () {
      final iso =
          now.toUtc().subtract(const Duration(minutes: 5)).toIso8601String();
      expect(formatNotificationTime(iso, now: now), '5 min ago');
    });

    test('a UTC timestamp shows its local date', () {
      const iso = '2026-10-01T23:30:00Z';
      final local = DateTime.parse(iso).toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = local.month.toString().padLeft(2, '0');
      expect(
        formatNotificationTime(iso, now: now),
        '$day/$month/${local.year}',
      );
    });

    test('returns empty string for unparseable input', () {
      expect(formatNotificationTime('', now: now), '');
      expect(formatNotificationTime('not-a-date', now: now), '');
    });
  });
}
