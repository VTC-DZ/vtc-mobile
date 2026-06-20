import '../../../../ride/shared/models/shared_ride_models.dart';

final class DriverServiceTypeRequest {
  const DriverServiceTypeRequest({
    required this.type,
    required this.enabled,
  });

  final ServiceType type;
  final bool enabled;

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        'enabled': enabled,
      };
}

final class DriverServiceTypesResponse {
  const DriverServiceTypesResponse({required this.activeServiceTypes});

  final Set<ServiceType> activeServiceTypes;

  factory DriverServiceTypesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['activeServiceTypes'] as List<dynamic>? ?? const [];
    return DriverServiceTypesResponse(
      activeServiceTypes:
          raw.map((e) => ServiceType.fromJson(e as String)).toSet(),
    );
  }
}
