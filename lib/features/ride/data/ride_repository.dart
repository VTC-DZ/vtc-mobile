import '../../../core/constants/ride_api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/ride_models.dart';

final class RideRepository {
  const RideRepository();

  Future<CreateRideResponse> createRide(CreateRideRequest request) async {
    final response = await DioClient.post(
      path: RideApiConstants.create,
      data: request.toJson(),
    );
    return CreateRideResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
