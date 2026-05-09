// lib/core/network/dio_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../constants/cache_keys.dart';
import '../constants/passenger_api_constants.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
import '../storage/secure_storage_helper.dart';
import '../../features/auth/data/models/auth_tokens_model.dart';

final class DioClient {
  DioClient._();

  static late Dio _dio;
  static String? _accessToken;
  static String? _refreshToken;
  static bool _isRefreshing = false;

  static bool get isLoggedIn => _accessToken != null;

  static void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        headers: {
          Headers.contentTypeHeader: Headers.jsonContentType,
          Headers.acceptHeader: Headers.jsonContentType,
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode != 401 ||
              _isRefreshing ||
              _refreshToken == null) {
            return handler.next(error);
          }

          _isRefreshing = true;
          try {
            final response = await _dio.post(
              PassengerApiConstants.refresh,
              data: {'refreshToken': _refreshToken},
              options: Options(
                headers: {'Authorization': null},
              ),
            );
            final tokens = AuthTokensModel.fromJson(
              response.data as Map<String, dynamic>,
            );
            await updateToken(tokens.accessToken);
            await updateRefreshToken(tokens.refreshToken);

            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
            final retried = await _dio.fetch(retryOptions);
            handler.resolve(retried);
          } catch (_) {
            await removeToken();
            AppRouter.router.go(RouteNames.phone);
            handler.next(error);
          } finally {
            _isRefreshing = false;
          }
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }
  }

  /// Loads persisted tokens into memory. Call once at app startup after [init].
  static Future<void> loadToken() async {
    _accessToken = await SecureStorageHelper.read(
      key: CacheKeys.secureStorageKeys.accessTokenKey,
    );
    _refreshToken = await SecureStorageHelper.read(
      key: CacheKeys.secureStorageKeys.refreshTokenKey,
    );
  }

  /// Saves the access token in memory and to secure storage.
  static Future<void> updateToken(String token) async {
    _accessToken = token;
    await SecureStorageHelper.write(
      key: CacheKeys.secureStorageKeys.accessTokenKey,
      value: token,
    );
  }

  /// Saves the refresh token in memory and to secure storage.
  static Future<void> updateRefreshToken(String token) async {
    _refreshToken = token;
    await SecureStorageHelper.write(
      key: CacheKeys.secureStorageKeys.refreshTokenKey,
      value: token,
    );
  }

  /// Clears both tokens from memory and secure storage.
  static Future<void> removeToken() async {
    _accessToken = null;
    _refreshToken = null;
    await SecureStorageHelper.remove(
      key: CacheKeys.secureStorageKeys.accessTokenKey,
    );
    await SecureStorageHelper.remove(
      key: CacheKeys.secureStorageKeys.refreshTokenKey,
    );
  }

  static Future<Response> get({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  static Future<Response> post({
    required String path,
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  static Future<Response> put({
    required String path,
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  static Future<Response> delete({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  static Future<Response> patch({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  static String _handleDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Request timed out. Check your connection.',
      DioExceptionType.connectionError => 'No connection. Check your network.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
