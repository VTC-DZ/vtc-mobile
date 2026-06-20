import '../../../../core/constants/driver_api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../ride/shared/models/shared_ride_models.dart';
import 'models/driver_service_types_models.dart';

final class DriverServiceTypesRepository {
  const DriverServiceTypesRepository();

  /// Toggles a single service type and returns the driver's full updated set.
  Future<Set<ServiceType>> setServiceType(
    ServiceType type,
    bool enabled,
  ) async {
    final response = await DioClient.put(
      path: DriverApiConstants.serviceTypes,
      data: DriverServiceTypeRequest(type: type, enabled: enabled).toJson(),
    );
    return DriverServiceTypesResponse.fromJson(
      response.data as Map<String, dynamic>,
    ).activeServiceTypes;
  }
}
