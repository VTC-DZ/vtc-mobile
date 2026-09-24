import 'package:equatable/equatable.dart';

/// One row of `GET /api/passenger/places/search`. Carries no coordinates —
/// resolve it via `GET /api/passenger/places/{placeId}` to get a position.
class PlaceSummary extends Equatable {
  const PlaceSummary({
    required this.placeId,
    required this.displayName,
    this.formattedAddress = '',
  });

  final String placeId;
  final String displayName;
  final String formattedAddress;

  /// Best text to show as the picked address.
  String get label => formattedAddress.isNotEmpty ? formattedAddress : displayName;

  factory PlaceSummary.fromJson(Map<String, dynamic> json) {
    return PlaceSummary(
      placeId: json['placeId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      formattedAddress: json['formattedAddress'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [placeId, displayName, formattedAddress];
}

/// Response of `GET /api/passenger/places/{placeId}` and
/// `GET /api/passenger/places/reverse-geocode`.
class PlaceDetail extends Equatable {
  const PlaceDetail({
    required this.placeId,
    required this.displayName,
    this.formattedAddress = '',
    required this.lat,
    required this.lng,
  });

  final String placeId;
  final String displayName;
  final String formattedAddress;
  final double lat;
  final double lng;

  /// Best text to show as the picked address.
  String get label => formattedAddress.isNotEmpty ? formattedAddress : displayName;

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as Map<String, dynamic>? ?? const {};
    return PlaceDetail(
      placeId: json['placeId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      formattedAddress: json['formattedAddress'] as String? ?? '',
      lat: (coordinates['lat'] as num?)?.toDouble() ?? 0,
      lng: (coordinates['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [placeId, displayName, formattedAddress, lat, lng];
}
