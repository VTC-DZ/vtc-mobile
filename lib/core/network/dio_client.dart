import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../constants/auth_api_constants.dart';
import '../errors/api_error_model.dart';
import '../errors/api_exception.dart';
import '../session/auth_session.dart';
import '../session/session_teardown.dart';
import '../utils/uuid.dart';
import '../models/auth_tokens_model.dart';
import 'ride_socket_service.dart';

final class DioClient {
  DioClient._();

  static late Dio _dio;
  static Completer<String>? _refreshCompleter;

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
          // Respect an explicitly provided Authorization header — e.g. the
          // `Authorization: null` that refreshAccessToken sets to strip the
          // stale bearer — instead of overwriting it. Other auth endpoints
          // (switch-role, logout) still receive the access token normally.
          final token = AuthSession.accessToken;
          if (token != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    // Attach a unique Idempotency-Key to every mutating request so the server
    // can safely de-duplicate retries. Auth endpoints are excluded — the refresh
    // call is internal and must not carry a key.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final method = options.method.toUpperCase();
          final isAuth = options.path.startsWith(AuthApiConstants.base);
          if (!isAuth &&
              (method == 'POST' || method == 'PUT' || method == 'DELETE')) {
            options.headers['Idempotency-Key'] = uuidV4();
          }
          handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode != 401 ||
              AuthSession.refreshToken == null) {
            return handler.next(error);
          }

          // The server rejected the session. This is the only place a failed
          // refresh ends it: the refresh call's 401 passes through here before
          // refreshAccessToken() fails, so the teardown runs once however many
          // requests joined that refresh.
          //
          // That 401 must not be fed back into refreshAccessToken(): the
          // refresh call is the very one populating _refreshCompleter, so
          // recursing here would await a completer that can only be completed
          // by this call — deadlocking every request waiting on the shared
          // refresh.
          if (isSessionRejected(error)) {
            await SessionTeardown.run();
            return handler.next(error);
          }

          // All concurrent 401s join the same in-flight refresh instead of
          // each racing/failing independently — otherwise only the first
          // request to 401 benefits and the rest get force-logged-out even
          // though the refresh succeeds moments later.
          final String newAccessToken;
          try {
            newAccessToken = await refreshAccessToken();
          } catch (_) {
            // A rejected refresh has already ended the session, on its own
            // pass through this handler. A timeout, no network or a 5xx keeps
            // the session: pass the original error on, and the next request
            // tries the refresh again.
            return handler.next(error);
          }

          // Refresh succeeded. A retry that still fails (persistent 401, a 403,
          // a transient) is NOT an auth-revocation signal — surface it to the
          // caller so the Cubit maps it to a normal failure state, but keep the
          // session intact.
          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          try {
            handler.resolve(await _dio.fetch(retryOptions));
          } on DioException catch (retryError) {
            handler.next(retryError);
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

  /// Refreshes the access token, sharing a single in-flight request across
  /// any 401s that arrive concurrently rather than firing one refresh call
  /// per request. Public so [RideSocketService] can join the same in-flight
  /// refresh instead of racing it with its own `/api/auth/refresh` call —
  /// the backend rotates refresh tokens on use, so two concurrent refreshes
  /// with the same (now-stale) token would leave the loser force-logged-out
  /// even though the winner already renewed the session.
  static Future<String> refreshAccessToken() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<String>();
    _refreshCompleter = completer;

    Future(() async {
      final response = await _dio.post(
        AuthApiConstants.refresh,
        data: {'refreshToken': AuthSession.refreshToken},
        options: Options(
          headers: {'Authorization': null},
        ),
      );
      final tokens = AuthTokensModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      await AuthSession.setTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens.accessToken;
    }).then(completer.complete).catchError((Object e, StackTrace s) {
      completer.completeError(e, s);
    }).whenComplete(() {
      _refreshCompleter = null;
    });

    return completer.future;
  }

  /// Whether [error] means the server rejected the session, so it must end:
  /// a 401 from `/api/auth/*` — from the refresh call, `session_invalid`.
  /// A timeout, no network or a 5xx never does; a 401 from any other endpoint
  /// only means the access token expired, which a refresh fixes.
  @visibleForTesting
  static bool isSessionRejected(DioException error) =>
      error.response?.statusCode == 401 &&
      error.requestOptions.path.startsWith(AuthApiConstants.base);

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
      throw await _handleDioError(e);
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
      throw await _handleDioError(e);
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
      throw await _handleDioError(e);
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
      throw await _handleDioError(e);
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
      throw await _handleDioError(e);
    }
  }

  static Future<Response> postMultipart({
    required String path,
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw await _handleDioError(e);
    }
  }

  static Future<ApiException> _handleDioError(DioException e) async {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final apiError = ApiErrorModel.tryParse(data);
    if (apiError != null && apiError.message.isNotEmpty) {
      // Auth-revocation logout is owned solely by the 401 onError interceptor
      // (which only tears down when the server rejects the refresh with a
      // 401). Do not log out here — a persistent 401/403 after a healthy
      // refresh is surfaced as a normal error, not a reason to clear the
      // session.
      return ApiException(
        message: apiError.message,
        code: apiError.code,
        statusCode: status,
        retryAfter: _retryAfter(e.response),
      );
    }
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Request timed out. Check your connection.',
      DioExceptionType.connectionError => 'No connection. Check your network.',
      _ => 'Something went wrong. Please try again.',
    };
    return ApiException(message: message, statusCode: status);
  }

  static Duration? _retryAfter(Response? response) {
    final seconds = int.tryParse(response?.headers.value('retry-after') ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
