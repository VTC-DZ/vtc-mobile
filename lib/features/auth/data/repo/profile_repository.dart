import '../../../../core/constants/me_api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/session/auth_session.dart';
import '../models/auth_tokens_model.dart';
import '../models/gender.dart';
import '../models/passenger_profile_model.dart';

final class ProfileRepository {
  const ProfileRepository();

  Future<PassengerProfileModel> getProfile() async {
    final response = await DioClient.get(path: MeApiConstants.profile);
    print('response profile : ${response.data}');
    return PassengerProfileModel.fromJson(
        response.data as Map<String, dynamic>);
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
        'dateOfBirth':
            '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
      },
    );
    return PassengerProfileModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
