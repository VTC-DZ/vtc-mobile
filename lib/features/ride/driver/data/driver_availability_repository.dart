import '../../../../core/constants/driver_api_constants.dart';
import '../../../../core/network/dio_client.dart';

final class DriverAvailabilityRepository {
  const DriverAvailabilityRepository();

  Future<bool> goOnline() async {
    final response = await DioClient.post(
      path: DriverApiConstants.goOnline,
      data: <String, dynamic>{},
    );
    return (response.data as Map<String, dynamic>)['isOnline'] as bool? ?? true;
  }

  Future<bool> goOffline() async {
    final response = await DioClient.post(
      path: DriverApiConstants.goOffline,
      data: <String, dynamic>{},
    );
    return (response.data as Map<String, dynamic>)['isOnline'] as bool? ?? false;
  }
}
