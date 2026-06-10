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

  Future<OfferListResponse> listOffers(String rideRequestId) async {
    final response = await DioClient.get(
      path: RideApiConstants.offers(rideRequestId),
    );
    return OfferListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AcceptOfferResponse> acceptOffer(
    String rideRequestId,
    String offerId,
  ) async {
    final response = await DioClient.post(
      path: RideApiConstants.acceptOffer(rideRequestId, offerId),
      data: <String, dynamic>{},
    );
    return AcceptOfferResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RefuseOfferResponse> refuseOffer(
    String rideRequestId,
    String offerId,
  ) async {
    final response = await DioClient.post(
      path: RideApiConstants.refuseOffer(rideRequestId, offerId),
      data: <String, dynamic>{},
    );
    return RefuseOfferResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActiveRideResponse> getActiveRide() async {
    final response = await DioClient.get(path: RideApiConstants.active);
    return ActiveRideResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
