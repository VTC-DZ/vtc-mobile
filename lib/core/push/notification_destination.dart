import '../models/token_payload.dart';
import '../router/route_names.dart';

/// Where a notification tap leads. `replace` means `go`, which replaces the
/// stack; otherwise it is a `push`, so back returns to where the user was.
typedef NotificationDestination = ({String path, Object? extra, bool replace});

/// The tap routing table of NOTIFICATION_PROGRESS.md, as a pure function.
///
/// Returns `null` when the tap should open nothing: the "none" rows, a target
/// in the other role's shell (its API calls would 403 with this role's token),
/// and an unknown key that announces no inbox item.
NotificationDestination? resolveNotificationDestination({
  required String eventKey,
  required Map<String, String> data,
  required ActiveRole role,
}) {
  if (role == ActiveRole.unknown) return null;
  final isDriver = role == ActiveRole.driver;

  return switch (eventKey) {
    'ride.broadcasted' => isDriver ? _go(RouteNames.availableRides) : null,
    'offer.accepted' => isDriver ? _go(RouteNames.driverActiveRide) : null,
    'ride.accepted' ||
    'ride.arrived' =>
      isDriver ? null : _go(RouteNames.passengerActiveRide),
    'ride.started' => _go(
        isDriver ? RouteNames.driverActiveRide : RouteNames.passengerActiveRide,
      ),
    // The passenger ride detail is keyed by rideRequestId, which these
    // payloads don't carry, so the passenger lands on ride history instead.
    'ride.completed' || 'ride.cancelled' => isDriver
        ? _driverRide(data['rideId'])
        : _push(RouteNames.passengerRideHistory),
    'wallet.topup_approved' ||
    'wallet.topup_rejected' =>
      isDriver ? _push(RouteNames.driverTopUpHistory) : null,
    'wallet.penalty_charged' ||
    'wallet.balance_low' ||
    'wallet.balance_adjusted' =>
      isDriver ? _push(RouteNames.driverWallet) : null,
    // The status review screen blocks back navigation, so it is only ever
    // reached with go.
    'kyc.approved' ||
    'kyc.rejected' ||
    'driver.revoked' ||
    'driver.reinstated' =>
      _go(RouteNames.driverStatusReview),
    // The home and waiting-offers flows reconcile these on their own.
    'offer.created' ||
    'ride.request_cancelled' ||
    'offer.rejected' ||
    'offer.expired' ||
    'ride.broadcast_cancelled' =>
      null,
    _ when eventKey.startsWith('user.') || data.containsKey('notificationId') =>
      _push(
        isDriver
            ? RouteNames.driverNotifications
            : RouteNames.passengerNotifications,
      ),
    _ => null,
  };
}

/// The ride's detail when the payload names it, otherwise the ride history,
/// rather than a detail screen with no id to load.
NotificationDestination _driverRide(String? rideId) =>
    rideId == null || rideId.isEmpty
        ? _push(RouteNames.driverRideHistory)
        : _push(RouteNames.driverRideDetail, extra: rideId);

NotificationDestination _go(String path) =>
    (path: path, extra: null, replace: true);

NotificationDestination _push(String path, {Object? extra}) =>
    (path: path, extra: extra, replace: false);
