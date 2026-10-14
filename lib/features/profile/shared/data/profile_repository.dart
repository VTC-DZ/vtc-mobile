import '../../../../core/constants/me_api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/models/auth_tokens_model.dart';
import '../../../../core/models/gender.dart';
import '../../../../core/utils/calendar_date.dart';
import 'models/driver_profile_model.dart';
import 'models/passenger_profile_model.dart';

/// The signed-in user's account under `/api/me`: profile, email and phone.
///
/// Not `final`, so tests can extend it with a fake.
class ProfileRepository {
  const ProfileRepository();

  Future<PassengerProfileModel> getProfile() async {
    final response = await DioClient.get(path: MeApiConstants.profile);
    return PassengerProfileModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// The same `GET /api/me/profile`, read as the driver view of the account.
  Future<DriverProfileModel> getDriverProfile() async {
    final response = await DioClient.get(path: MeApiConstants.profile);
    return DriverProfileModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<PassengerProfileModel> updateEmail({required String email}) async {
    final response = await DioClient.patch(
      path: MeApiConstants.updateEmail,
      data: {'email': email},
    );
    return PassengerProfileModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<int> requestPhoneChange({required String newPhone}) async {
    final response = await DioClient.post(
      path: MeApiConstants.phoneRequest,
      data: {'newPhone': newPhone},
    );
    return response.data['expiresIn'] as int;
  }

  Future<void> confirmPhoneChange({
    required String newPhone,
    required String code,
  }) async {
    final response = await DioClient.post(
      path: MeApiConstants.phoneConfirm,
      data: {'newPhone': newPhone, 'code': code},
    );

    final tokens =
        AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    await AuthSession.setTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  Future<PassengerProfileModel> saveProfile({
    required String fullName,
    required Gender gender,
    required DateTime dateOfBirth,
  }) async {
    final response = await DioClient.put(
      path: MeApiConstants.profile,
      data: {
        'fullName': fullName,
        'gender': gender.name.toUpperCase(),
        'dateOfBirth': toApiDate(dateOfBirth),
      },
    );
    // A saved profile ends onboarding, so the app stops opening on mode
    // selection (KycRepository.submitKyc applies the same rule).
    await AuthSession.setIsNewUser(false);
    return PassengerProfileModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
