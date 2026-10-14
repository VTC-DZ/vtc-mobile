// lib/core/constants/app_strings.dart

/// UI copy written by the app. Text that comes from the server (error
/// messages, notifications) is shown as received and never lives here.
abstract final class AppStrings {
  AppStrings._();

  // ── Common ───────────────────────────────────────────────────────────────

  static const String continueLabel = 'Continue';
  static const String retry = 'Retry';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String logout = 'Logout';
  static const String logoutConfirm = 'Are you sure you want to logout?';

  // ── Phone entry ──────────────────────────────────────────────────────────

  static const String phoneEmpty = 'Please enter your phone number.';
  static const String phoneInvalid =
      'Enter a valid Algerian number (05/06/07 followed by 8 digits).';
  static const String phoneTitle = 'Enter your phone number';
  static const String phoneSubtitle = "We'll send you a verification code";
  static const String phoneTerms =
      'By continuing you agree to our Terms & Privacy';
  static const String sendCodeFailed =
      'Could not send the code. Please try again.';

  // ── OTP ──────────────────────────────────────────────────────────────────

  static const String otpAppBarTitle = 'Verification';
  static const String otpTitle = 'Verify your number';
  static const String otpCodeSentTo = 'Code sent to ';
  static const String verify = 'Verify';
  static const String otpIncorrect = 'Incorrect code, try again';
  static const String otpResendFailed =
      'Could not resend OTP. Please try again.';
  static const String otpResend = 'Resend Code';
  static const String otpResendExhausted = 'Maximum resend attempts reached';
  static String otpResendIn(String countdown) => 'Resend code in $countdown';
  static String otpResendsRemaining(int count) =>
      '$count resend${count == 1 ? '' : 's'} remaining';
  static const String otpLockedTitle = 'Account Temporarily Locked';
  static const String otpLockedBody =
      'Too many incorrect attempts.\nPlease try again in';
  static const String otpWrongNumber = 'Wrong number? ';
  static const String otpChangeNumber = 'Change Number';

  // ── Mode selection ───────────────────────────────────────────────────────

  static const String modeTitle = 'How would you like\nto use the app?';
  static const String modeSubtitle = 'Choose your path to get started';
  static const String modePassenger = 'Passenger';
  static const String modePassengerBody = 'Book rides and travel comfortably';
  static const String modeDriver = 'Driver';
  static const String modeDriverBody = 'Drive, earn, and be your own boss';

  // ── Profile form fields (passenger setup, driver step 1, profile edit) ───

  static const String profileSetupTitle = 'Complete your\nprofile';
  static const String profileSetupSubtitle =
      'Just a few quick details to get you started';
  static const String fieldFullName = 'Full Name';
  static const String fieldFirstName = 'First Name';
  static const String fieldLastName = 'Last Name';
  static const String fieldDateOfBirth = 'Date of Birth';
  static const String fieldGender = 'Gender';
  static const String genderMale = 'Male';
  static const String genderFemale = 'Female';
  static const String hintFullName = 'e.g. Youcef Benali';
  static const String hintDate = 'DD/MM/YYYY';

  // ── Driver registration ──────────────────────────────────────────────────

  // Steps
  static const String stepPersonal = 'Personal';
  static const String stepVehicle = 'Vehicle';
  static const String stepDocuments = 'Documents';
  static const String submitApplication = 'Submit Application';
  static String completeStepFirst(int step) =>
      'Please complete step $step first.';

  // Field labels
  static const String fieldVehicleType = 'Vehicle Type';
  static const String fieldCarModel = 'Model';
  static const String fieldYear = 'Year';
  static const String fieldColor = 'Color';
  static const String fieldPlateNumber = 'Plate Number';
  static const String fieldInsuranceExpiry = 'Insurance Expiry';
  static const String fieldVehiclePhoto = 'Vehicle Photo';
  static const String fieldInsurance = 'Insurance';
  static const String fieldLicenseNumber = 'License Number';
  static const String fieldLicenseExpiry = 'License Expiry';
  static const String fieldLicensePhotos = 'License Photos';
  static const String fieldNationalId = 'National ID';
  static const String docVehicleRegistration = 'Vehicle Registration';

  // Hints and pickers
  static const String hintCarModel = 'e.g. Toyota Corolla';
  static const String hintPlate = 'e.g. 12345-123-12';
  static const String hintLicenseNumber = 'e.g. 123456789';
  static const String hintExpiryDate = 'Expiry date';
  static const String selectType = 'Select type';
  static const String selectVehicleType = 'Select Vehicle Type';
  static const String selectYear = 'Select year';
  static const String selectYearTitle = 'Select Year';
  static const String selectColor = 'Select color';
  static const String selectColorTitle = 'Select Color';
  static const String documentRequirements =
      'JPG, PNG or PDF • Max 5 MB per file';

  // Document cards
  static const String docBadgePhoto = 'PHOTO';
  static const String docBadgeInsurance = 'INS';
  static const String docBadgeRegistration = 'REG';
  static const String docBadgeFront = 'FRONT';
  static const String docBadgeBack = 'BACK';
  static const String docSideFront = 'Front';
  static const String docSideBack = 'Back';
  static const String docTapToUpload = 'Tap to add';
  static const String docUploading = 'Adding…';
  static const String docUploaded = 'Added';
  static const String docTapToChange = 'Tap to change';
  static const String docFailedRetry = 'Failed — retry';

  // Document source sheet
  static const String docSourceTitle = 'Add document';
  static const String docSourceCamera = 'Camera';
  static const String docSourceCameraHint = 'Take a photo';
  static const String docSourceGallery = 'Gallery';
  static const String docSourceGalleryHint = 'Pick from your photos';
  static const String docSourceFile = 'File';
  static const String docSourceFileHint = 'Choose a PDF or an image';

  // Validation errors
  static const String plateRequired = 'Plate number is required';
  static const String plateInvalid = 'Enter a valid plate (e.g. 12345-123-12)';
  static const String licenseNumberRequired = 'License number is required';
  static const String fileTooLarge = 'File exceeds 5 MB limit';
  static const String fileTypeNotAllowed = 'Use a JPG, PNG or PDF file';
  static const String documentPickFailed =
      'Could not add that file. Tap to retry.';
  static const String submissionFailed = 'Submission failed. Please try again.';
  static String uploadingDocuments(int percent) =>
      'Uploading documents… $percent%';
  static const String personalInfoSaveFailed =
      'Could not save your details. Please try again.';
  static const String leaveApplicationTitle = 'Leave your application?';
  static const String leaveApplicationBody =
      'What you have entered so far will be lost.';
  static const String leaveApplication = 'Leave';
  static const String stayOnApplication = 'Stay';

  // ── KYC status ───────────────────────────────────────────────────────────

  static const String pendingReviewTitle = 'Under Review';
  static const String pendingReviewBody =
      "Your documents have been submitted and are currently being reviewed by our team. You'll be notified within 24–48 hours.";
  static const String rejectionTitle = 'Application Rejected';
  static const String revokedTitle = 'Driver Access Revoked';
  static const String revokedResubmitBody =
      'Re-submit your documents to get driver access back.';
  static const String revokedNoResubmitBody =
      "Re-submission isn't available for this account. Contact support to get driver access back.";
  static const String rejectionReasonLabel = 'Reason:';
  static const String rejectionDefaultReason =
      'Your application did not meet our requirements.';
  static const String resubmitDocuments = 'Re-submit Documents';
  static const String goToHome = 'Continue as Passenger';
  static const String statusLoadingTitle = 'Checking Status...';
  static const String statusErrorTitle = 'Something Went Wrong';
  static const String statusErrorBody =
      'We could not retrieve your verification status. Please try again.';
  static const String kycStatusLoadFailed = 'Failed to load KYC status.';
}
