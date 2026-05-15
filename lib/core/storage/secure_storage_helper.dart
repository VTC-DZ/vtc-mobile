// lib/core/storage/secure_storage_helper.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/cache_keys.dart';

class SecureStorageHelper {
  static late FlutterSecureStorage _storage;

  static void init() {
    _storage = const FlutterSecureStorage();
  }

  static Future<void> write({
    required String key,
    required String value,
  }) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  static Future<void> remove({required String key}) async {
    await _storage.delete(key: key);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await write(
      key: CacheKeys.secureStorageKeys.accessTokenKey,
      value: accessToken,
    );
    if (refreshToken != null) {
      await write(
        key: CacheKeys.secureStorageKeys.refreshTokenKey,
        value: refreshToken,
      );
    }
  }

  static void removeAllSecureStorage() {
    _storage.deleteAll();
  }
}
