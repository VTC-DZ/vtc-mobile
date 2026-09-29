abstract final class PassengerRideApiConstants {
  PassengerRideApiConstants._();

  static const String _base = '/api/passenger/rides';

  static const String create = _base;

  /// Paginated ride history (completed + cancelled rides, newest first).
  static const String history = _base;
  static String offers(String rideRequestId) => '$_base/$rideRequestId/offers';
  static String acceptOffer(String rideRequestId, String offerId) =>
      '$_base/$rideRequestId/offers/$offerId/accept';
  static String refuseOffer(String rideRequestId, String offerId) =>
      '$_base/$rideRequestId/offers/$offerId/refuse';
  static String counterOffer(String rideRequestId) =>
      '$_base/$rideRequestId/counter-offer';
  static String cancel(String rideRequestId) => '$_base/$rideRequestId/cancel';

  /// Detail of a past or current ride, keyed by its ride *request* id.
  static String detail(String rideRequestId) => '$_base/$rideRequestId';
  static const String active = '$_base/active';
}

/// Ride error codes from the API error envelope that the passenger app branches
/// on, so nothing sniffs message text. See swagger/epic-03-ride.md §12 — every
/// other ride `409` is treated generically as "your view is stale".
abstract final class PassengerRideErrorCodes {
  PassengerRideErrorCodes._();

  /// `409` — create while a request/ride is already live; route to it.
  static const String rideAlreadyActive = 'RIDE_ALREADY_ACTIVE';

  /// `429` — create during the post-cancel cooldown; count down, then allow.
  static const String rideCreateCooldown = 'RIDE_CREATE_COOLDOWN';
}
