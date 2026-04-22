// lib/core/constants/app_strings.dart

abstract final class AppStrings {
  AppStrings._();

  static const String phoneEmpty = 'Please enter your phone number.';
  static const String phoneInvalid =
      'Enter a valid Algerian number (05/06/07 followed by 8 digits).';

  // ── Driver Registration ──────────────────────────────────────────────────

  // Step headers
  static const String driverStep1Title = 'Tell us about\nyourself';
  static const String driverStep1Subtitle = 'Start with your basic personal details';
  static const String driverStep2Title = 'Your vehicle\ndetails';
  static const String driverStep2Subtitle = 'Share your vehicle information';
  static const String driverStep3Title = 'Upload your\ndocuments';
  static const String driverStep3Subtitle = 'We need to verify your identity and vehicle';

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
}
