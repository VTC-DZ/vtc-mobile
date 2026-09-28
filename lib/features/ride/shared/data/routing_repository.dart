import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/routing_api_constants.dart';
import 'models/road_route.dart';

/// Fetches road routes for the active-ride maps.
///
/// Deliberately does **not** go through `DioClient`: that client attaches our
/// JWT to every request (which must never reach a third-party host) and treats
/// 401/403 as a forced logout. The routing provider gets its own bare [Dio].
class RoutingRepository {
  const RoutingRepository();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: RoutingApiConstants.baseUrl,
      connectTimeout:
          const Duration(milliseconds: RoutingApiConstants.connectTimeoutMs),
      receiveTimeout:
          const Duration(milliseconds: RoutingApiConstants.receiveTimeoutMs),
    ),
  );

  Future<RoadRoute> drivingRoute(LatLng from, LatLng to) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        RoutingApiConstants.drivingRoute(from, to),
        queryParameters: RoutingApiConstants.routeQuery,
      );
      return RoadRoute.fromOsrmJson(response.data ?? const {});
    } on DioException catch (e) {
      throw 'Could not load the route: ${e.message}';
    } on FormatException catch (e) {
      throw 'Could not load the route: ${e.message}';
    }
  }
}
