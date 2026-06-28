// lib/core/constants/cache_keys.dart

abstract final class CacheKeys {
  CacheKeys._();

  static const SecureStorageKeys secureStorageKeys = SecureStorageKeys();
}

class SecureStorageKeys {
  const SecureStorageKeys();

  String get accessTokenKey => 'access_token';
  String get refreshTokenKey => 'refresh_token';
  String get isNewUserKey => 'is_new_user';
  String get isWaitingKyc => 'is_waiting_kyc';
  String get hasDriverProfile => 'has_driver_profile';
  String get driverKycStatus => 'driver_kyc_status';
  String get lastRoleKey => 'last_role';
}
