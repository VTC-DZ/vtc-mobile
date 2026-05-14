import '../utils/jwt_decoder.dart';

enum ActiveRole { passenger, driver, unknown }

class TokenPayload {
  const TokenPayload({
    required this.sub,
    required this.aud,
    required this.kycVerified,
    required this.hasDriverProfile,
    required this.gender,
    required this.accountType,
    required this.iss,
    required this.exp,
    required this.iat,
    required this.jti,
    required this.activeRole,
  });

  final String sub;
  final String aud;
  final bool kycVerified;
  final bool hasDriverProfile;
  final String gender;
  final String accountType;
  final String iss;
  final int exp;
  final int iat;
  final String jti;
  final ActiveRole activeRole;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp;

  factory TokenPayload.fromJson(Map<String, dynamic> json) {
    return TokenPayload(
      sub: json['sub'] as String? ?? '',
      aud: json['aud'] as String? ?? '',
      kycVerified: json['kycVerified'] as bool? ?? false,
      hasDriverProfile: json['hasDriverProfile'] as bool? ?? false,
      gender: json['gender'] as String? ?? '',
      accountType: json['accountType'] as String? ?? '',
      iss: json['iss'] as String? ?? '',
      exp: json['exp'] as int? ?? 0,
      iat: json['iat'] as int? ?? 0,
      jti: json['jti'] as String? ?? '',
      activeRole: _parseActiveRole(json['activeRole'] as String?),
    );
  }

  factory TokenPayload.fromToken(String token) {
    final decoded = JwtDecoder.decode(token);
    return TokenPayload.fromJson(decoded);
  }

  static ActiveRole _parseActiveRole(String? value) {
    if (value == null) return ActiveRole.unknown;
    return switch (value.toUpperCase()) {
      'PASSENGER' => ActiveRole.passenger,
      'DRIVER' => ActiveRole.driver,
      _ => ActiveRole.unknown,
    };
  }
}
