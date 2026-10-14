import '../utils/jwt_decoder.dart';

/// The role a JWT is issued for (its `activeRole` claim), and the value
/// `POST /api/auth/switch-role` takes.
enum ActiveRole {
  passenger('PASSENGER'),
  driver('DRIVER'),
  unknown('');

  const ActiveRole(this.wireValue);

  /// The backend's spelling, e.g. `DRIVER`.
  final String wireValue;

  /// Parses [value] case-insensitively; anything unrecognised is [unknown].
  static ActiveRole fromWire(String? value) =>
      switch (value?.toUpperCase()) {
        'PASSENGER' => ActiveRole.passenger,
        'DRIVER' => ActiveRole.driver,
        _ => ActiveRole.unknown,
      };
}

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

  bool get isExpired => DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp;

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
      activeRole: ActiveRole.fromWire(json['activeRole'] as String?),
    );
  }

  factory TokenPayload.fromToken(String token) {
    final decoded = JwtDecoder.decode(token);
    return TokenPayload.fromJson(decoded);
  }

  @override
  String toString() {
    return 'TokenPayload{sub: $sub, aud: $aud, kycVerified: $kycVerified, hasDriverProfile: $hasDriverProfile, gender: $gender, accountType: $accountType, iss: $iss, exp: $exp, iat: $iat, jti: $jti, activeRole: $activeRole}';
  }
}
