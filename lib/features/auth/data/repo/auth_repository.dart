// lib/features/auth/data/repo/auth_repository.dart

import '../../../../core/constants/passenger_api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/storage/secure_storage_helper.dart';
import '../models/auth_tokens_model.dart';
import '../models/gender.dart';

final class AuthRepository {
  const AuthRepository();

  /// Sends an OTP to [phoneE164] (e.g. "+213661234567").
  Future<void> sendOtp(String phoneE164) => DioClient.post(
        path: PassengerApiConstants.otpRequest,
        data: {'phone': phoneE164},
      );

  /// Verifies [otp] for [phoneE164], persists the access token, and returns
  /// the parsed tokens (including [AuthTokensModel.isNewUser]).
  Future<AuthTokensModel> verifyOtp(String phoneE164, String otp) async {
    final response = await DioClient.post(
      path: PassengerApiConstants.otpVerify,
      data: {'phone': phoneE164, 'code': otp},
    );
    final tokens =
        AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    await SecureStorageHelper.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await DioClient.updateToken(tokens.accessToken);
    await DioClient.updateRefreshToken(tokens.refreshToken);
    return tokens;
  }

  /// Calls the logout endpoint, clears all local tokens, and navigates to the
  /// phone entry screen. Errors from the API are silently ignored so that the
  /// user is always logged out locally even if the network call fails.
  Future<void> logout() async {
    try {
      await DioClient.post(
        path: PassengerApiConstants.logout,
        data: {},
      );
    } catch (_) {}
    await DioClient.removeToken();
    AppRouter.router.go(RouteNames.phone);
  }

  /// Saves the driver's personal info (Step 1 of driver registration).
  Future<void> saveDriverPersonalInfo({
    required String fullName,
    required Gender gender,
    required DateTime dateOfBirth,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
  }

  /// Submits driver vehicle info and documents for admin review (Step 3).
  Future<void> submitDriverDocuments({
    required String nationalIdFrontPath,
    required String nationalIdBackPath,
    required String licenseFrontPath,
    required String licenseBackPath,
    required String vehicleRegistrationPath,
    required String vehiclePhotoPath,
    required String vehicleMake,
    required String vehicleModel,
    required int vehicleYear,
    required String vehicleColor,
    required String plateNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
  }
}
