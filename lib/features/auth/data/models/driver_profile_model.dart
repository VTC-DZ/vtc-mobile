import 'kyc_status.dart';

class DriverProfileModel {
  const DriverProfileModel({
    required this.fullName,
    required this.gender,
    required this.phone,
    required this.kycStatus,
    required this.acceptsFemaleOnly,
  });

  final String fullName;
  final String gender;
  final String phone;
  final KycStatus kycStatus;
  final bool acceptsFemaleOnly;

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      fullName: json['fullName'] as String? ?? '',
      gender: json['gender'] as String? ?? 'MALE',
      phone: json['phone'] as String? ?? '',
      kycStatus: KycStatus.fromString(json['kycStatus'] as String?),
      acceptsFemaleOnly: json['acceptsFemaleOnly'] as bool? ?? false,
    );
  }
}
