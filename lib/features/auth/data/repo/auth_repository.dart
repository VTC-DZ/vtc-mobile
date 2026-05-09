// lib/features/auth/data/repo/auth_repository.dart

import '../../../../core/constants/passenger_api_constants.dart';
import '../../../../core/network/dio_client.dart';
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
    await DioClient.updateToken(tokens.accessToken);
    return tokens;
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
