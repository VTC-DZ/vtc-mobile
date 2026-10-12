import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/models/page_response.dart';
import 'package:rapidoo/features/notifications/data/models/app_notification.dart';

/// Fixtures mirror `NotificationResponse` in `swagger/account.json` and the
/// inbox example in the backend's `docs/api/account.md`.
void main() {
  group('AppNotification.fromJson', () {
    test('maps a full payload field by field', () {
      final item = AppNotification.fromJson({
        'id': 'notification-uuid',
        'eventKey': 'wallet.topup_approved',
        'title': 'Recharge approuvée',
        'body': 'Votre recharge de 1000 DA a été créditée.',
        'data': {
          'topUpId': 'topup-uuid',
          'creditedAmountDzd': '1000',
          'balanceDzd': '2500',
        },
        'read': true,
        'createdAt': '2026-10-10T09:15:00Z',
        'readAt': '2026-10-10T09:20:00Z',
      });

      expect(item.id, 'notification-uuid');
      expect(item.eventKey, 'wallet.topup_approved');
      expect(item.title, 'Recharge approuvée');
      expect(item.body, 'Votre recharge de 1000 DA a été créditée.');
      expect(item.data, {
        'topUpId': 'topup-uuid',
        'creditedAmountDzd': '1000',
        'balanceDzd': '2500',
      });
      expect(item.read, isTrue);
      expect(item.createdAt, '2026-10-10T09:15:00Z');
      expect(item.readAt, '2026-10-10T09:20:00Z');
    });

    test('coerces non-string data values and drops null ones', () {
      final item = AppNotification.fromJson({
        'id': 'notification-2',
        'eventKey': 'driver.revoked',
        'data': {
          'driverId': 'driver-uuid',
          'requireRekyc': true,
          'days': 3,
          'reason': null,
        },
      });

      expect(item.data, {
        'driverId': 'driver-uuid',
        'requireRekyc': 'true',
        'days': '3',
      });
    });

    test('tolerates a missing or null data and readAt', () {
      final missing = AppNotification.fromJson({'id': 'notification-3'});
      final nulls = AppNotification.fromJson({
        'id': 'notification-4',
        'data': null,
        'readAt': null,
      });

      for (final item in [missing, nulls]) {
        expect(item.data, isEmpty);
        expect(item.readAt, isNull);
      }
      expect(missing.eventKey, '');
      expect(missing.title, '');
      expect(missing.body, '');
      expect(missing.read, isFalse);
      expect(missing.createdAt, '');
    });
  });

  test('copyWith(read:) flips read and keeps every other field', () {
    final unread = AppNotification.fromJson({
      'id': 'notification-5',
      'eventKey': 'ride.completed',
      'title': 'Course terminée',
      'body': 'Merci.',
      'data': {'rideId': 'ride-uuid'},
      'read': false,
      'createdAt': '2026-10-11T18:00:00Z',
    });

    final read = unread.copyWith(read: true);

    expect(read.read, isTrue);
    expect(unread.read, isFalse);
    expect(read.id, unread.id);
    expect(read.eventKey, unread.eventKey);
    expect(read.title, unread.title);
    expect(read.body, unread.body);
    expect(read.data, unread.data);
    expect(read.createdAt, unread.createdAt);
    expect(read.readAt, unread.readAt);
  });

  test('PageResponse drops a row without an id and keeps the rest', () {
    final page = PageResponse.fromJson(
      {
        'data': [
          {'id': 'notification-1', 'eventKey': 'ride.completed'},
          {'eventKey': 'ride.cancelled'},
          {'id': 'notification-3', 'eventKey': 'user.suspended'},
        ],
        'page': 0,
        'size': 20,
        'totalElements': 3,
        'totalPages': 1,
      },
      AppNotification.fromJson,
    );

    expect(
      page.data.map((item) => item.id),
      ['notification-1', 'notification-3'],
    );
  });
}
