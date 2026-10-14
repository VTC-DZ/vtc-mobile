/// `AuthTokensResponse` — returned by `POST /api/auth/otp/verify` and
/// `POST /api/auth/refresh` (and by `POST /api/me/phone/confirm`).
///
/// Only the two tokens are guaranteed; the flags default to `false` when the
/// server leaves them out, so a refresh response without them still parses.
class AuthTokensModel {
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    this.isNewUser = false,
    this.profileCompleted = false,
    this.hasDriverProfile = false,
  });

  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
  final bool profileCompleted;
  final bool hasDriverProfile;

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      isNewUser: json['isNewUser'] as bool? ?? false,
      profileCompleted: json['profileCompleted'] as bool? ?? false,
      hasDriverProfile: json['hasDriverProfile'] as bool? ?? false,
    );
  }
}
