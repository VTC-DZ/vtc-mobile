import '../constants/cache_keys.dart';
import '../models/token_payload.dart';
import '../router/route_names.dart';
import '../storage/secure_storage_helper.dart';

final class AuthSession {
  AuthSession._();

  static String? _accessToken;
  static String? _refreshToken;
  static TokenPayload? _tokenPayload;
  static bool? _isNewUser;

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;
  static TokenPayload? get tokenPayload => _tokenPayload;
  static bool get isLoggedIn => _accessToken != null;
  static bool get isNewUser => _isNewUser ?? false;

  /// Loads persisted session from secure storage. Call once at startup.
  static Future<void> loadSession() async {
    _accessToken = await SecureStorageHelper.read(
      key: CacheKeys.secureStorageKeys.accessTokenKey,
    );
    _refreshToken = await SecureStorageHelper.read(
      key: CacheKeys.secureStorageKeys.refreshTokenKey,
    );
    if (_accessToken != null) {
      _decodeAndCachePayload(_accessToken!);
    }
    final isNewUserStr = await SecureStorageHelper.read(
      key: CacheKeys.secureStorageKeys.isNewUserKey,
    );
    _isNewUser = isNewUserStr == 'true';
  }

  /// Saves tokens, decodes the JWT payload, and persists the role.
  static Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _decodeAndCachePayload(accessToken);
    final role = _tokenPayload?.activeRole.name;
    await SecureStorageHelper.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userRole: role,
    );
  }

  static Future<void> setIsNewUser(bool value) async {
    _isNewUser = value;
    await SecureStorageHelper.write(
      key: CacheKeys.secureStorageKeys.isNewUserKey,
      value: value.toString(),
    );
  }

  static Future<void> clearIsNewUser() async {
    _isNewUser = false;
    await SecureStorageHelper.remove(
      key: CacheKeys.secureStorageKeys.isNewUserKey,
    );
  }

  /// Clears all session state from memory and secure storage.
  static Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenPayload = null;
    _isNewUser = null;
    await SecureStorageHelper.remove(
      key: CacheKeys.secureStorageKeys.accessTokenKey,
    );
    await SecureStorageHelper.remove(
      key: CacheKeys.secureStorageKeys.refreshTokenKey,
    );
    await SecureStorageHelper.remove(
      key: CacheKeys.secureStorageKeys.isNewUserKey,
    );
    await SecureStorageHelper.remove(
      key: CacheKeys.secureStorageKeys.userRoleKey,
    );
  }

  static String resolveInitialRoute() {
    if (!isLoggedIn) return RouteNames.phone;
    if (isNewUser) return RouteNames.modeSelection;
    final role = _tokenPayload?.activeRole;
    if (role == ActiveRole.passenger) return RouteNames.passengerHome;
    return RouteNames.passengerHome;
  }

  static void _decodeAndCachePayload(String token) {
    try {
      _tokenPayload = TokenPayload.fromToken(token);
    } catch (_) {
      _tokenPayload = null;
    }
  }
}
