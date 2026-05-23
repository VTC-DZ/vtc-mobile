enum AddressType { home, work, other }

extension AddressTypeX on AddressType {
  String get apiValue => name.toUpperCase();

  static AddressType fromApi(String value) {
    return AddressType.values.firstWhere(
      (e) => e.apiValue == value.toUpperCase(),
      orElse: () => AddressType.other,
    );
  }
}

final class AddressModel {
  const AddressModel({
    this.id,
    required this.type,
    required this.label,
    required this.address,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.building,
    this.floor,
    this.door,
    this.description,
  });

  final String? id;
  final AddressType type;
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final String? building;
  final String? floor;
  final String? door;
  final String? description;

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String?,
      type: AddressTypeX.fromApi(json['type'] as String? ?? ''),
      label: json['label'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      building: json['building'] as String?,
      floor: json['floor'] as String?,
      door: json['door'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type.apiValue,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (building != null) 'building': building,
      if (floor != null) 'floor': floor,
      if (door != null) 'door': door,
      if (description != null) 'description': description,
    };
  }

  AddressModel copyWith({
    String? id,
    AddressType? type,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    String? building,
    String? floor,
    String? door,
    String? description,
  }) {
    return AddressModel(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      door: door ?? this.door,
      description: description ?? this.description,
    );
  }
}
