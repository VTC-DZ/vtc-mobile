// lib/core/constants/cache_keys.dart

abstract final class CacheKeys {
  CacheKeys._();

  static const SecureStorageKeys secureStorageKeys = SecureStorageKeys();
}

class SecureStorageKeys {
  const SecureStorageKeys();

  String get accessTokenKey => 'access_token';
  String get refreshTokenKey => 'refresh_token';
  String get idTokenKey => 'id_token';
  String get isNewUserKey => 'is_new_user';
  String get userRoleKey => 'user_role';
}
