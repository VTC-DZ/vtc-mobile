import 'package:equatable/equatable.dart';

import '../../../../../core/models/gender.dart';
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
    this.driverRequiresRekyc = false,
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

  /// `driver.requiresRekyc`: whether a revoked driver may send a new
  /// application. Without it the server refuses one (`REKYC_NOT_REQUIRED`).
  final bool driverRequiresRekyc;

  factory PassengerProfileModel.fromJson(Map<String, dynamic> json) {
    return PassengerProfileModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      gender: (json['gender'] as String? ?? '').toLowerCase() == 'female'
          ? Gender.female
          : Gender.male,
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] as String? ?? '') ??
          DateTime(2000),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? '',
      hasDriverProfile: json['hasDriverProfile'] as bool? ?? false,
      profileCompleted: json['profileCompleted'] as bool? ?? false,
      activeRole: json['activeRole'] as String? ?? 'PASSENGER',
      hasPassengerProfile: json['hasPassengerProfile'] as bool? ?? false,
      savedAddressCount:
          json['passenger']?['savedAddressCount'] as int? ?? 0,
      driverKycStatus: KycStatus.fromString(
        json['driver']?['kycStatus'] as String?,
      ),
      driverRequiresRekyc:
          json['driver']?['requiresRekyc'] as bool? ?? false,
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
    bool? driverRequiresRekyc,
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
        driverRequiresRekyc: driverRequiresRekyc ?? this.driverRequiresRekyc,
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
        driverRequiresRekyc,
      ];
}
