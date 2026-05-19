// lib/core/constants/app_strings.dart

abstract final class AppStrings {
  AppStrings._();

  static const String phoneEmpty = 'Please enter your phone number.';
  static const String phoneInvalid =
      'Enter a valid Algerian number (05/06/07 followed by 8 digits).';

  // ── Driver Registration ──────────────────────────────────────────────────

  // Field labels
  static const String fieldFirstName = 'First Name';
  static const String fieldLastName = 'Last Name';
  static const String fieldDateOfBirth = 'Date of Birth';
  static const String fieldGender = 'Gender';
  static const String fieldCarMake = 'Car Make';
  static const String fieldCarModel = 'Model';
  static const String fieldYear = 'Year';
  static const String fieldColor = 'Color';
  static const String fieldPlateNumber = 'Plate Number';
  static const String fieldVehiclePhoto = 'Vehicle Photo';

  // Document labels
  static const String docNationalIdFront = 'National ID — Front';
  static const String docNationalIdBack = 'National ID — Back';
  static const String docLicenseFront = "Driver's License — Front";
  static const String docLicenseBack = "Driver's License — Back";
  static const String docVehicleRegistration = 'Vehicle Registration';

  // Validation errors
  static const String plateRequired = 'Plate number is required';
  static const String plateInvalid = 'Enter a valid plate (e.g. 12345-123-12)';
  static const String dateOfBirthRequired = 'Date of birth is required';
  static const String vehiclePhotoRequired = 'Vehicle photo is required';
  static const String fileTooLarge = 'File exceeds 5 MB limit';

  // Terminal screens
  static const String pendingReviewTitle = 'Under Review';
  static const String pendingReviewBody =
      "Your documents have been submitted and are currently being reviewed by our team. You'll be notified within 24–48 hours.";
  static const String rejectionTitle = 'Application Rejected';
  static const String resubmitDocuments = 'Re-submit Documents';
  static const String goToHome = 'Continue as Passenger';

  // KYC Status Review
  static const String statusApprovedTitle = 'Approved';
  static const String statusApprovedBody =
      "Congratulations! Your documents have been approved. You're now ready to drive.";
  static const String statusLoadingTitle = 'Checking Status...';
  static const String statusErrorTitle = 'Something Went Wrong';
  static const String statusErrorBody =
      'We could not retrieve your verification status. Please try again.';
  static const String retry = 'Retry';
  static const String continueLabel = 'Continue';
}
