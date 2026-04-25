import '../../../data/models/gender.dart';
import '../../../data/models/driver_document.dart';

enum DriverRegistrationStatus { initial, loading, success, failure }

enum DriverStep { personalInfo, vehicleInfo, documents }

// ── Step data classes ─────────────────────────────────────────────────────────

final class DriverPersonalInfo {
  const DriverPersonalInfo({
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.gender,
    this.firstNameError = '',
    this.lastNameError = '',
  });

  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String firstNameError;
  final String lastNameError;

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  bool get isFirstNameValid =>
      firstNameError.isEmpty && firstName.trim().length >= 2;
  bool get isLastNameValid =>
      lastNameError.isEmpty && lastName.trim().length >= 2;
  bool get canProceed =>
      isFirstNameValid &&
      isLastNameValid &&
      dateOfBirth != null &&
      gender != null;

  DriverPersonalInfo copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    Gender? gender,
    String? firstNameError,
    String? lastNameError,
  }) {
    return DriverPersonalInfo(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      firstNameError: firstNameError ?? this.firstNameError,
      lastNameError: lastNameError ?? this.lastNameError,
    );
  }
}

final class DriverVehicleInfo {
  const DriverVehicleInfo({
    this.vehicleMake = '',
    this.vehicleModel = '',
    this.vehicleYear,
    this.vehicleColor = '',
    this.plateNumber = '',
    this.vehiclePhotoPath,
    this.vehicleMakeError = '',
    this.vehicleModelError = '',
    this.vehicleColorError = '',
    this.plateNumberError = '',
  });

  final String vehicleMake;
  final String vehicleModel;
  final int? vehicleYear;
  final String vehicleColor;
  final String plateNumber;
  final String? vehiclePhotoPath;
  final String vehicleMakeError;
  final String vehicleModelError;
  final String vehicleColorError;
  final String plateNumberError;

  bool get isVehicleMakeValid =>
      vehicleMakeError.isEmpty && vehicleMake.trim().length >= 2;
  bool get isVehicleModelValid =>
      vehicleModelError.isEmpty && vehicleModel.trim().length >= 2;
  bool get isVehicleColorValid =>
      vehicleColorError.isEmpty && vehicleColor.trim().length >= 2;
  bool get isPlateNumberValid =>
      plateNumberError.isEmpty && plateNumber.isNotEmpty;
  bool get canProceed =>
      isVehicleMakeValid &&
      isVehicleModelValid &&
      vehicleYear != null &&
      isVehicleColorValid &&
      isPlateNumberValid &&
      vehiclePhotoPath != null;

  DriverVehicleInfo copyWith({
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear,
    String? vehicleColor,
    String? plateNumber,
    String? vehiclePhotoPath,
    String? vehicleMakeError,
    String? vehicleModelError,
    String? vehicleColorError,
    String? plateNumberError,
  }) {
    return DriverVehicleInfo(
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      plateNumber: plateNumber ?? this.plateNumber,
      vehiclePhotoPath: vehiclePhotoPath ?? this.vehiclePhotoPath,
      vehicleMakeError: vehicleMakeError ?? this.vehicleMakeError,
      vehicleModelError: vehicleModelError ?? this.vehicleModelError,
      vehicleColorError: vehicleColorError ?? this.vehicleColorError,
      plateNumberError: plateNumberError ?? this.plateNumberError,
    );
  }
}

final class DriverDocuments {
  const DriverDocuments({
    this.nationalIdFront = const DriverDocument(),
    this.nationalIdBack = const DriverDocument(),
    this.licenseFront = const DriverDocument(),
    this.licenseBack = const DriverDocument(),
    this.vehicleRegistration = const DriverDocument(),
  });

  final DriverDocument nationalIdFront;
  final DriverDocument nationalIdBack;
  final DriverDocument licenseFront;
  final DriverDocument licenseBack;
  final DriverDocument vehicleRegistration;

  bool get allUploaded =>
      nationalIdFront.isUploaded &&
      nationalIdBack.isUploaded &&
      licenseFront.isUploaded &&
      licenseBack.isUploaded &&
      vehicleRegistration.isUploaded;

  DriverDocuments copyWith({
    DriverDocument? nationalIdFront,
    DriverDocument? nationalIdBack,
    DriverDocument? licenseFront,
    DriverDocument? licenseBack,
    DriverDocument? vehicleRegistration,
  }) {
    return DriverDocuments(
      nationalIdFront: nationalIdFront ?? this.nationalIdFront,
      nationalIdBack: nationalIdBack ?? this.nationalIdBack,
      licenseFront: licenseFront ?? this.licenseFront,
      licenseBack: licenseBack ?? this.licenseBack,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
    );
  }
}

// ── Root state ────────────────────────────────────────────────────────────────

final class DriverProfileState {
  const DriverProfileState({
    this.currentStep = DriverStep.personalInfo,
    this.status = DriverRegistrationStatus.initial,
    this.errorMessage = '',
    this.personalInfo = const DriverPersonalInfo(),
    this.vehicleInfo = const DriverVehicleInfo(),
    this.documents = const DriverDocuments(),
  });

  final DriverStep currentStep;
  final DriverRegistrationStatus status;
  final String errorMessage;
  final DriverPersonalInfo personalInfo;
  final DriverVehicleInfo vehicleInfo;
  final DriverDocuments documents;

  bool get canProceedStep1 =>
      personalInfo.canProceed && status != DriverRegistrationStatus.loading;

  bool get canProceedStep2 =>
      vehicleInfo.canProceed && status != DriverRegistrationStatus.loading;

  bool get canSubmitStep3 =>
      documents.allUploaded && status != DriverRegistrationStatus.loading;

  DriverProfileState copyWith({
    DriverStep? currentStep,
    DriverRegistrationStatus? status,
    String? errorMessage,
    DriverPersonalInfo? personalInfo,
    DriverVehicleInfo? vehicleInfo,
    DriverDocuments? documents,
  }) {
    return DriverProfileState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      personalInfo: personalInfo ?? this.personalInfo,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      documents: documents ?? this.documents,
    );
  }
}
