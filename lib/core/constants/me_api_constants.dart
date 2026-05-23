abstract final class MeApiConstants {
  MeApiConstants._();

  static const String _base = '/api/me';

  static const String profile = '$_base/profile';
  static const String updateEmail = '$_base/email';
  static const String phoneRequest = '$_base/phone/request';
  static const String phoneConfirm = '$_base/phone/confirm';
}
