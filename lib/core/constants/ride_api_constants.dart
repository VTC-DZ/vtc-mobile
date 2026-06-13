abstract final class PassengerRideApiConstants {
  PassengerRideApiConstants._();

  static const String _base = '/api/passenger/rides';

  static const String create = _base;
  static String offers(String rideRequestId) => '$_base/$rideRequestId/offers';
  static String acceptOffer(String rideRequestId, String offerId) =>
      '$_base/$rideRequestId/offers/$offerId/accept';
  static String refuseOffer(String rideRequestId, String offerId) =>
      '$_base/$rideRequestId/offers/$offerId/refuse';
  static String counterOffer(String rideRequestId) =>
      '$_base/$rideRequestId/counter-offer';
  static String cancel(String rideRequestId) => '$_base/$rideRequestId/cancel';
  static String get(String rideId) => '$_base/$rideId';
  static const String active = '$_base/active';
}
