import 'package:equatable/equatable.dart';

import 'gender.dart';

class PassengerProfileModel extends Equatable {
  const PassengerProfileModel({
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    this.email,
    this.phone,
  });

  final String fullName;
  final Gender gender;
  final DateTime dateOfBirth;
  final String? email;
  final String? phone;

  factory PassengerProfileModel.fromJson(Map<String, dynamic> json) {
    return PassengerProfileModel(
      fullName: json['fullName'] as String? ?? '',
      gender: (json['gender'] as String? ?? '').toLowerCase() == 'female'
          ? Gender.female
          : Gender.male,
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] as String? ?? '') ??
          DateTime(2000),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
  PassengerProfileModel copyWith({
    String? fullName,
    Gender? gender,
    DateTime? dateOfBirth,
    String? email,
    String? phone,
  }) =>
      PassengerProfileModel(
        fullName: fullName ?? this.fullName,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        email: email ?? this.email,
        phone: phone ?? this.phone,
      );

  @override
  List<Object?> get props => [fullName, gender, dateOfBirth, email, phone];
}
