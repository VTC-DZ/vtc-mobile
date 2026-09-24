import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/places_api_constants.dart';
import '../../../../core/network/dio_client.dart';
import 'models/place_models.dart';

final class PlacesRepository {
  const PlacesRepository();

  /// [sessionToken] groups the keystrokes of one autocomplete session (reset
  /// after a [resolve]); [bias] ranks results near that position.
  Future<List<PlaceSummary>> search(
    String q, {
    String? sessionToken,
    LatLng? bias,
  }) async {
    final response = await DioClient.get(
      path: PlacesApiConstants.search,
      queryParameters: {
        'q': q,
        if (sessionToken != null) 'sessionToken': sessionToken,
        if (bias != null) 'bias': '${bias.latitude},${bias.longitude}',
      },
    );
    final list = response.data['results'] as List<dynamic>? ?? const [];
    return list
        .map((e) => PlaceSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlaceDetail> resolve(String placeId) async {
    final response = await DioClient.get(
      path: PlacesApiConstants.resolve(Uri.encodeComponent(placeId)),
    );
    return PlaceDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlaceDetail> reverseGeocode(LatLng position) async {
    final response = await DioClient.get(
      path: PlacesApiConstants.reverseGeocode,
      queryParameters: {
        'lat': position.latitude,
        'lng': position.longitude,
      },
    );
    return PlaceDetail.fromJson(response.data as Map<String, dynamic>);
  }
}
