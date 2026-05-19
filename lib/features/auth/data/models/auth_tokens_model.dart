// lib/features/auth/data/models/auth_tokens_model.dart

/// Response model for POST /api/passenger/auth/otp/verify
/// and POST /api/passenger/auth/refresh.
///
/// Expected JSON:
/// { "accessToken": "...", "refreshToken": "...", "isNewUser": true, "profileCompleted": true }
class AuthTokensModel {
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
    this.profileCompleted,
    this.hasDriverProfile = false,
  });

  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
  final bool? profileCompleted;
  final bool hasDriverProfile;

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      isNewUser: json['isNewUser'],
      profileCompleted: json['profileCompleted'] ?? false,
      hasDriverProfile: json['hasDriverProfile'] ?? false,
    );
  }
}
