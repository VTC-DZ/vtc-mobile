import 'package:equatable/equatable.dart';

import 'gender.dart';
import 'kyc_status.dart';

class PassengerProfileModel extends Equatable {
  const PassengerProfileModel({
    required this.id,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.status,
    required this.hasDriverProfile,
    required this.profileCompleted,
    required this.activeRole,
    required this.hasPassengerProfile,
    required this.savedAddressCount,
    required this.driverKycStatus,
    this.email,
    this.phone,
  });

  final String id;
  final String fullName;
  final Gender gender;
  final DateTime dateOfBirth;
  final String? email;
  final String? phone;
  final String status;
  final bool hasDriverProfile;
  final bool profileCompleted;
  final String activeRole;
  final bool hasPassengerProfile;
  final int savedAddressCount;
  final KycStatus driverKycStatus;

  factory PassengerProfileModel.fromJson(Map<String, dynamic> json) {
    return PassengerProfileModel(
      id: json['id'],
      fullName: json['fullName'],
      gender: (json['gender'] as String? ?? '').toLowerCase() == 'female'
          ? Gender.female
          : Gender.male,
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']) ?? DateTime(2000),
      email: json['email'],
      phone: json['phone'],
      status: json['status'],
      hasDriverProfile: json['hasDriverProfile'] as bool? ?? false,
      profileCompleted: json['profileCompleted'] as bool? ?? false,
      activeRole: json['activeRole'] as String? ?? 'PASSENGER',
      hasPassengerProfile: json['hasPassengerProfile'] as bool? ?? false,
      savedAddressCount:
          json['passenger']?['savedAddressCount'] as int? ?? 0,
      driverKycStatus: KycStatus.fromString(
        json['driver']?['kycStatus'] as String?,
      ),
    );
  }

  PassengerProfileModel copyWith({
    String? id,
    String? fullName,
    Gender? gender,
    DateTime? dateOfBirth,
    String? email,
    String? phone,
    String? status,
    bool? hasDriverProfile,
    bool? profileCompleted,
    String? activeRole,
    bool? hasPassengerProfile,
    int? savedAddressCount,
    KycStatus? driverKycStatus,
  }) =>
      PassengerProfileModel(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        status: status ?? this.status,
        hasDriverProfile: hasDriverProfile ?? this.hasDriverProfile,
        profileCompleted: profileCompleted ?? this.profileCompleted,
        activeRole: activeRole ?? this.activeRole,
        hasPassengerProfile: hasPassengerProfile ?? this.hasPassengerProfile,
        savedAddressCount: savedAddressCount ?? this.savedAddressCount,
        driverKycStatus: driverKycStatus ?? this.driverKycStatus,
      );

  @override
  List<Object?> get props => [
        id,
        fullName,
        gender,
        dateOfBirth,
        email,
        phone,
        status,
        hasDriverProfile,
        profileCompleted,
        activeRole,
        hasPassengerProfile,
        savedAddressCount,
        driverKycStatus,
      ];
}
