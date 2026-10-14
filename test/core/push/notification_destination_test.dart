import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/models/token_payload.dart';
import 'package:rapidoo/core/push/notification_destination.dart';
import 'package:rapidoo/core/router/route_names.dart';

/// Mirrors the tap routing table in NOTIFICATION_PROGRESS.md.
void main() {
  NotificationDestination? resolve(
    String eventKey,
    ActiveRole role, [
    Map<String, String> data = const {},
  ]) =>
      resolveNotificationDestination(
        eventKey: eventKey,
        data: data,
        role: role,
      );

  NotificationDestination go(String path) =>
      (path: path, extra: null, replace: true);

  NotificationDestination push(String path, [Object? extra]) =>
      (path: path, extra: extra, replace: false);

  const inboxItem = {'notificationId': 'notification-uuid'};
  const statusDecisions = [
    'kyc.approved',
    'kyc.rejected',
    'driver.revoked',
    'driver.reinstated',
  ];
  const accountItems = ['user.blocked', 'user.suspended', 'user.reactivated'];
  const reconciledElsewhere = [
    'offer.created',
    'ride.request_cancelled',
    'offer.rejected',
    'offer.expired',
    'ride.broadcast_cancelled',
  ];

  group('passenger role', () {
    const role = ActiveRole.passenger;

    test('trip progress goes to the active ride', () {
      for (final key in ['ride.accepted', 'ride.arrived', 'ride.started']) {
        expect(resolve(key, role), go(RouteNames.passengerActiveRide),
            reason: key);
      }
    });

    test('a finished ride opens the ride history', () {
      for (final key in ['ride.completed', 'ride.cancelled']) {
        expect(
          resolve(key, role, {...inboxItem, 'rideId': 'ride-uuid'}),
          push(RouteNames.passengerRideHistory),
          reason: key,
        );
      }
    });

    test('KYC and driver decisions go to the status review', () {
      for (final key in statusDecisions) {
        expect(resolve(key, role, inboxItem), go(RouteNames.driverStatusReview),
            reason: key);
      }
    });

    test('account items open the passenger inbox', () {
      for (final key in accountItems) {
        expect(resolve(key, role, inboxItem),
            push(RouteNames.passengerNotifications),
            reason: key);
      }
    });

    test('driver targets and the reconciled keys open nothing', () {
      for (final key in [
        'ride.broadcasted',
        'offer.accepted',
        ...reconciledElsewhere,
      ]) {
        expect(resolve(key, role), isNull, reason: key);
      }
    });

    test('driver-inbox wallet items open nothing, even with an inbox id', () {
      for (final key in [
        'wallet.topup_approved',
        'wallet.topup_rejected',
        'wallet.penalty_charged',
        'wallet.balance_low',
        'wallet.balance_adjusted',
      ]) {
        expect(resolve(key, role, inboxItem), isNull, reason: key);
      }
    });
  });

  group('driver role', () {
    const role = ActiveRole.driver;

    test('a broadcast opens the available rides', () {
      expect(resolve('ride.broadcasted', role), go(RouteNames.availableRides));
    });

    test('an accepted offer and a started trip go to the active ride', () {
      for (final key in ['offer.accepted', 'ride.started']) {
        expect(resolve(key, role), go(RouteNames.driverActiveRide),
            reason: key);
      }
    });

    test('a finished ride opens its detail with the rideId as extra', () {
      for (final key in ['ride.completed', 'ride.cancelled']) {
        expect(
          resolve(key, role, {...inboxItem, 'rideId': 'ride-uuid'}),
          push(RouteNames.driverRideDetail, 'ride-uuid'),
          reason: key,
        );
      }
    });

    test('a finished ride without a rideId opens the ride history', () {
      expect(resolve('ride.completed', role, inboxItem),
          push(RouteNames.driverRideHistory));
      expect(resolve('ride.cancelled', role, {...inboxItem, 'rideId': ''}),
          push(RouteNames.driverRideHistory));
    });

    test('top-up decisions open the top-up history', () {
      for (final key in ['wallet.topup_approved', 'wallet.topup_rejected']) {
        expect(
            resolve(key, role, inboxItem), push(RouteNames.driverTopUpHistory),
            reason: key);
      }
    });

    test('balance movements open the wallet', () {
      for (final key in [
        'wallet.penalty_charged',
        'wallet.balance_low',
        'wallet.balance_adjusted',
      ]) {
        expect(resolve(key, role, inboxItem), push(RouteNames.driverWallet),
            reason: key);
      }
    });

    test('KYC and driver decisions go to the status review', () {
      for (final key in statusDecisions) {
        expect(resolve(key, role, inboxItem), go(RouteNames.driverStatusReview),
            reason: key);
      }
    });

    test('account items open the driver inbox', () {
      for (final key in accountItems) {
        expect(
            resolve(key, role, inboxItem), push(RouteNames.driverNotifications),
            reason: key);
      }
    });

    test('passenger targets and the reconciled keys open nothing', () {
      for (final key in [
        'ride.accepted',
        'ride.arrived',
        ...reconciledElsewhere,
      ]) {
        expect(resolve(key, role), isNull, reason: key);
      }
    });
  });

  group('unknown keys', () {
    test('with an inbox id, open the role inbox', () {
      expect(resolve('promo.new', ActiveRole.passenger, inboxItem),
          push(RouteNames.passengerNotifications));
      expect(resolve('promo.new', ActiveRole.driver, inboxItem),
          push(RouteNames.driverNotifications));
      expect(resolve('', ActiveRole.driver, inboxItem),
          push(RouteNames.driverNotifications));
    });

    test('without an inbox id, open nothing', () {
      for (final role in [ActiveRole.passenger, ActiveRole.driver]) {
        expect(resolve('promo.new', role), isNull, reason: role.name);
      }
    });
  });

  test('an unknown role opens nothing', () {
    for (final key in ['ride.started', 'kyc.approved', 'user.blocked']) {
      expect(resolve(key, ActiveRole.unknown, inboxItem), isNull, reason: key);
    }
  });
}
