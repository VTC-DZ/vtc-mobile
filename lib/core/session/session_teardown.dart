import '../network/driver_location_streamer.dart';
import '../network/ride_socket_service.dart';
import '../push/push_notification_service.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
import 'auth_session.dart';

/// Ends the session on this device: stops GPS streaming, closes the ride
/// socket, clears [AuthSession], removes the notifications the app is showing
/// and returns to phone entry.
///
/// Every way a session ends goes through here — logout, a token refresh the
/// server rejects (`DioClient`) and a socket the server revokes
/// ([RideSocketService]) — so the socket can never outlive the session it was
/// opened for (it would keep auto-reconnecting on its backoff schedule).
final class SessionTeardown {
  SessionTeardown._();

  static Future<void> run() async {
    DriverLocationStreamer.stop();
    await RideSocketService.disconnect();
    await AuthSession.clearSession();
    await PushNotificationService.clearDisplayed();
    AppRouter.router.go(RouteNames.phone);
  }
}
