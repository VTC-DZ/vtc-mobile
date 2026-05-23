abstract final class DriverApiConstants {
  DriverApiConstants._();

  static const String _base = '/api/driver';

  // Registration
  static const String registration = '$_base/registration';

  // KYC
  static const String kycSubmit = '$_base/kyc/submit';
  static const String kycStatus = '$_base/kyc/status';
}
