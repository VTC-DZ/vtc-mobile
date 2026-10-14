import 'dart:async';

import '../../../core/constants/auth_api_constants.dart';
import '../../../core/models/token_payload.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/driver_location_streamer.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/session/session_teardown.dart';
import '../../../core/models/auth_tokens_model.dart';

/// Phone-OTP login, role switching and logout (`/api/auth/*`).
///
/// Not `final`, so tests can extend it with a fake.
class AuthRepository {
  const AuthRepository();

  /// Sends an OTP to [phoneE164] (e.g. "+213661234567").
  Future<void> sendOtp(String phoneE164) => DioClient.post(
        path: AuthApiConstants.otpRequest,
        data: {'phone': phoneE164},
      );

  /// Verifies [otp] for [phoneE164], persists the tokens and the onboarding
  /// flags, registers this device for push, and returns the parsed tokens
  /// (including [AuthTokensModel.isNewUser]).
  Future<AuthTokensModel> verifyOtp(String phoneE164, String otp) async {
    final response = await DioClient.post(
      path: AuthApiConstants.otpVerify,
      data: {'phone': phoneE164, 'code': otp},
    );
    final tokens =
        AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    await AuthSession.setTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await AuthSession.setIsNewUser(tokens.isNewUser);
    if (tokens.hasDriverProfile) {
      await AuthSession.setHasDriverProfile(true);
    }
    // The server clears the stored push token on every login.
    unawaited(PushNotificationService.registerDevice());
    return tokens;
  }

  /// Swaps the access token for one whose `activeRole` is [targetRole].
  ///
  /// Leaving the driver role also stops GPS streaming and closes the driver
  /// socket, which only a `DRIVER` token may hold open.
  Future<void> switchRole(ActiveRole targetRole) async {
    final response = await DioClient.post(
      path: AuthApiConstants.switchRole,
      data: {'targetRole': targetRole.wireValue},
    );
    final data = response.data as Map<String, dynamic>;
    if (targetRole == ActiveRole.passenger) {
      DriverLocationStreamer.stopAndDisconnect();
    }
    await AuthSession.setAccessToken(data['accessToken'] as String);
  }

  /// Calls the logout endpoint, then ends the session on this device
  /// ([SessionTeardown]). API errors are ignored so that the user is always
  /// logged out locally, even when the network call fails.
  Future<void> logout() async {
    // With this device's token the server unregisters only this device;
    // without one it clears whichever token is stored, even another device's.
    final pushToken = await PushNotificationService.currentToken();
    try {
      await DioClient.post(
        path: AuthApiConstants.logout,
        data: {if (pushToken != null) 'pushToken': pushToken},
      );
    } catch (_) {}
    await SessionTeardown.run();
  }
}
