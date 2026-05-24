import 'kyc_status.dart';

class DriverProfileModel {
  const DriverProfileModel({
    required this.fullName,
    required this.gender,
    required this.phone,
    required this.kycStatus,
    required this.acceptsFemaleOnly,
    this.email,
  });

  final String fullName;
  final String gender;
  final String phone;
  final KycStatus kycStatus;
  final bool acceptsFemaleOnly;
  final String? email;

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      fullName: json['fullName'] as String? ?? '',
      gender: json['gender'] as String? ?? 'MALE',
      phone: json['phone'] as String? ?? '',
      kycStatus: KycStatus.fromString(json['kycStatus'] as String?),
      acceptsFemaleOnly: json['acceptsFemaleOnly'] as bool? ?? false,
      email: json['email'] as String?,
    );
  }

  DriverProfileModel copyWith({
    String? fullName,
    String? gender,
    String? phone,
    KycStatus? kycStatus,
    bool? acceptsFemaleOnly,
    String? email,
  }) {
    return DriverProfileModel(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      kycStatus: kycStatus ?? this.kycStatus,
      acceptsFemaleOnly: acceptsFemaleOnly ?? this.acceptsFemaleOnly,
      email: email ?? this.email,
    );
  }
}
