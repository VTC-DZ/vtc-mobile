import '../models/token_payload.dart';
import '../session/auth_session.dart';
import 'route_names.dart';

/// The first screen for a stored session.
///
/// Pure so the rules can be unit-tested; [initialRouteForSession] feeds it the
/// flags [AuthSession] holds.
String resolveInitialRoute({
  required bool isLoggedIn,
  required bool isNewUser,
  required bool waitingKycStatus,
  required bool hasDriverProfile,
  required ActiveRole lastRole,
}) {
  if (!isLoggedIn) return RouteNames.phone;
  // A submitted or approved driver application means onboarding is done, even
  // if the isNewUser flag was never cleared (sessions from older builds).
  if (isNewUser && !waitingKycStatus && !hasDriverProfile) {
    return RouteNames.modeSelection;
  }
  if (lastRole == ActiveRole.driver) return RouteNames.driverHome;
  return RouteNames.passengerHome;
}

/// [resolveInitialRoute] for the session [AuthSession] holds right now.
String initialRouteForSession() => resolveInitialRoute(
      isLoggedIn: AuthSession.isLoggedIn,
      isNewUser: AuthSession.isNewUser,
      waitingKycStatus: AuthSession.waitingKycStatus,
      hasDriverProfile: AuthSession.hasDriverProfile,
      lastRole: AuthSession.lastRole,
    );
