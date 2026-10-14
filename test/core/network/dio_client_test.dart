import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/constants/auth_api_constants.dart';
import 'package:rapidoo/core/constants/me_api_constants.dart';
import 'package:rapidoo/core/network/dio_client.dart';

void main() {
  DioException failure(
    String path, {
    int? status,
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    final options = RequestOptions(path: path);
    return DioException(
      requestOptions: options,
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(requestOptions: options, statusCode: status),
    );
  }

  group('DioClient.isSessionRejected', () {
    test('a 401 from the refresh (session_invalid) ends the session', () {
      expect(
        DioClient.isSessionRejected(
          failure(AuthApiConstants.refresh, status: 401),
        ),
        isTrue,
      );
    });

    test('a 5xx from the refresh keeps the session', () {
      expect(
        DioClient.isSessionRejected(
          failure(AuthApiConstants.refresh, status: 500),
        ),
        isFalse,
      );
    });

    test('a refresh that times out keeps the session', () {
      expect(
        DioClient.isSessionRejected(
          failure(
            AuthApiConstants.refresh,
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        isFalse,
      );
    });

    test('a refresh with no network keeps the session', () {
      expect(
        DioClient.isSessionRejected(
          failure(
            AuthApiConstants.refresh,
            type: DioExceptionType.connectionError,
          ),
        ),
        isFalse,
      );
    });

    test('a 401 from any other endpoint is refreshed, not rejected', () {
      expect(
        DioClient.isSessionRejected(
          failure(MeApiConstants.profile, status: 401),
        ),
        isFalse,
      );
    });
  });
}
