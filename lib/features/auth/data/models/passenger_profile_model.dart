import 'package:equatable/equatable.dart';

import 'gender.dart';

class PassengerProfileModel extends Equatable {
  const PassengerProfileModel({
    required this.id,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.status,
    required this.hasDriverProfile,
    required this.profileCompleted,
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
      hasDriverProfile: json['hasDriverProfile'],
      profileCompleted: json['profileCompleted'],
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
      ];
}
