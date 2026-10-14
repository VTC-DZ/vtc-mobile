import 'package:equatable/equatable.dart';

import '../../../../core/utils/algerian_plate.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../ride/shared/models/shared_ride_models.dart';

/// Everything `POST /api/driver/kyc/submit` needs: the `KycSubmitRequest`
/// fields and the local paths of the document photos.
///
/// [toFields] owns the wire format — field names, `yyyy-MM-dd` dates, the
/// spaced plate, the upper-case category — so the wizard never sees it.
final class KycSubmission extends Equatable {
  const KycSubmission({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.vehicleCategory,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    required this.vehicleYear,
    required this.insuranceExpiry,
    required this.nationalIdPaths,
    required this.driverLicensePaths,
    required this.grayCardPath,
    required this.insurancePath,
    required this.carPicturePaths,
  });

  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final VehicleCategory vehicleCategory;
  final String vehicleModel;
  final String vehicleColor;

  /// As typed: `NNNNN-NNN-NN`.
  final String vehiclePlate;
  final int vehicleYear;
  final DateTime insuranceExpiry;

  /// Front, then back.
  final List<String> nationalIdPaths;

  /// Front, then back.
  final List<String> driverLicensePaths;

  /// The vehicle registration ("carte grise").
  final String grayCardPath;
  final String insurancePath;
  final List<String> carPicturePaths;

  /// The `KycSubmitRequest` text parts.
  Map<String, String> toFields() => {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'dateOfBirth': toApiDate(dateOfBirth),
        'licenseNumber': licenseNumber.trim(),
        'licenseExpiry': toApiDate(licenseExpiry),
        'vehicleCategory': vehicleCategory.toJson(),
        'vehicleModel': vehicleModel.trim(),
        'vehicleColor': vehicleColor.trim(),
        'vehiclePlate': AlgerianPlate.toWire(vehiclePlate),
        'vehicleYear': '$vehicleYear',
        'insuranceExpiry': toApiDate(insuranceExpiry),
      };

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        dateOfBirth,
        licenseNumber,
        licenseExpiry,
        vehicleCategory,
        vehicleModel,
        vehicleColor,
        vehiclePlate,
        vehicleYear,
        insuranceExpiry,
        nationalIdPaths,
        driverLicensePaths,
        grayCardPath,
        insurancePath,
        carPicturePaths,
      ];
}
