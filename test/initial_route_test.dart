import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/models/token_payload.dart';
import 'package:rapidoo/core/router/initial_route.dart';
import 'package:rapidoo/core/router/route_names.dart';

String _route({
  bool isLoggedIn = true,
  bool isNewUser = false,
  bool waitingKycStatus = false,
  bool hasDriverProfile = false,
  ActiveRole lastRole = ActiveRole.unknown,
}) =>
    resolveInitialRoute(
      isLoggedIn: isLoggedIn,
      isNewUser: isNewUser,
      waitingKycStatus: waitingKycStatus,
      hasDriverProfile: hasDriverProfile,
      lastRole: lastRole,
    );

void main() {
  test('no session starts on phone entry, whatever else is stored', () {
    expect(
      _route(isLoggedIn: false, isNewUser: true, lastRole: ActiveRole.driver),
      RouteNames.phone,
    );
  });

  test('a new user who has not applied as a driver picks a mode', () {
    expect(_route(isNewUser: true), RouteNames.modeSelection);
  });

  test('a submitted or approved driver application ends onboarding', () {
    expect(_route(isNewUser: true, waitingKycStatus: true),
        RouteNames.passengerHome);
    expect(_route(isNewUser: true, hasDriverProfile: true),
        RouteNames.passengerHome);
    expect(
      _route(
          isNewUser: true,
          hasDriverProfile: true,
          lastRole: ActiveRole.driver),
      RouteNames.driverHome,
    );
  });

  test('a returning user opens the home of the last role', () {
    expect(_route(lastRole: ActiveRole.driver), RouteNames.driverHome);
    expect(_route(lastRole: ActiveRole.passenger), RouteNames.passengerHome);
    expect(_route(), RouteNames.passengerHome);
  });

  test('ActiveRole round-trips its wire value', () {
    for (final role in [ActiveRole.passenger, ActiveRole.driver]) {
      expect(ActiveRole.fromWire(role.wireValue), role);
    }
    expect(ActiveRole.fromWire('driver'), ActiveRole.driver);
    expect(ActiveRole.fromWire(null), ActiveRole.unknown);
    expect(ActiveRole.fromWire('ADMIN'), ActiveRole.unknown);
  });
}
