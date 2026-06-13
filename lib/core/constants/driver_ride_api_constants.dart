abstract final class DriverRideApiConstants {
  DriverRideApiConstants._();

  static const String _base = '/api/driver/rides';

  static const String available = '$_base/available';
  static String bid(String rideRequestId) => '$_base/$rideRequestId/bid';
  static String arrived(String rideId) => '$_base/$rideId/arrived';
  static String start(String rideId) => '$_base/$rideId/start';
  static String complete(String rideId) => '$_base/$rideId/complete';
  static String cancel(String rideId) => '$_base/$rideId/cancel';
  static const String active = '$_base/active';
}
