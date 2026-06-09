import 'package:flutter/material.dart';

enum VehicleCategory {
  car,
  motorcycle,
  van;

  String get label => switch (this) {
        VehicleCategory.car => 'Car',
        VehicleCategory.motorcycle => 'Motorcycle',
        VehicleCategory.van => 'Van',
      };

  IconData get icon => switch (this) {
        VehicleCategory.car => Icons.directions_car_rounded,
        VehicleCategory.motorcycle => Icons.two_wheeler_rounded,
        VehicleCategory.van => Icons.airport_shuttle_rounded,
      };

  String toJson() => name.toUpperCase();

  static VehicleCategory fromJson(String value) => VehicleCategory.values
      .firstWhere((e) => e.toJson() == value.toUpperCase());
}
