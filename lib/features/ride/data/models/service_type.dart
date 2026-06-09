import 'package:flutter/material.dart';

enum ServiceType {
  ride,
  delivery;

  String get label => switch (this) {
        ServiceType.ride => 'Ride',
        ServiceType.delivery => 'Delivery',
      };

  IconData get icon => switch (this) {
        ServiceType.ride => Icons.directions_car_rounded,
        ServiceType.delivery => Icons.local_shipping_rounded,
      };

  String toJson() => name.toUpperCase();

  static ServiceType fromJson(String value) =>
      ServiceType.values.firstWhere((e) => e.toJson() == value.toUpperCase());
}
