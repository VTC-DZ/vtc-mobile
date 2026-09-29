abstract final class DriverRideApiConstants {
  DriverRideApiConstants._();

  static const String _base = '/api/driver/rides';

  /// Paginated ride history (completed + cancelled rides, newest first).
  static const String history = _base;

  /// Full detail for a single past ride.
  static String detail(String rideId) => '$_base/$rideId';

  static const String available = '$_base/available';
  static String bid(String rideRequestId) => '$_base/$rideRequestId/bid';
  static String arrived(String rideId) => '$_base/$rideId/arrived';
  static String start(String rideId) => '$_base/$rideId/start';
  static String complete(String rideId) => '$_base/$rideId/complete';
  static String cancel(String rideId) => '$_base/$rideId/cancel';
  static const String active = '$_base/active';
}

/// Ride error codes from the API error envelope that the driver app branches
/// on, so nothing sniffs message text. See swagger/epic-03-ride.md §12 — every
/// other ride `409` is treated generically as "your view is stale".
abstract final class RideErrorCodes {
  RideErrorCodes._();

  /// `409` — `PASSENGER_NO_SHOW` cancel before `arrivalWaitDeadline` passed.
  static const String arrivalGraceNotElapsed = 'ARRIVAL_GRACE_NOT_ELAPSED';

  /// `409` — bid while already on a ride; route to the active-ride screen.
  static const String driverHasActiveRide = 'DRIVER_HAS_ACTIVE_RIDE';
}
