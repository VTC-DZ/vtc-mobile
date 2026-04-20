// lib/features/auth/data/models/otp_response_model.dart

/// API response model for POST /auth/send-otp.
///
/// Expected JSON: { "expiresIn": 60 }
class OtpResponseModel {
  const OtpResponseModel({required this.expiresIn});

  final int expiresIn;

  factory OtpResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpResponseModel(
      expiresIn: json['expiresIn'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toJson() => {'expiresIn': expiresIn};

  @override
  String toString() => 'OtpResponseModel(expiresIn: $expiresIn)';
}
