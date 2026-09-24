import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/map_geo.dart';
import '../../../../core/utils/map_marker_factory.dart';

/// The marker bitmaps shared by the passenger and driver active-ride maps.
final class RideMapIcons {
  const RideMapIcons({
    required this.pickup,
    required this.dropoff,
    required this.car,
    required this.userDot,
  });

  final MapMarkerIcon pickup;
  final MapMarkerIcon dropoff;
  final BitmapDescriptor car;
  final BitmapDescriptor userDot;

  static Future<RideMapIcons> load() async {
    final (pickup, dropoff, car, userDot) = await (
      MapMarkerFactory.locationPin(
        color: AppColors.primary,
        icon: Icons.person_rounded,
        label: 'Pickup',
      ),
      MapMarkerFactory.locationPin(
        color: AppColors.error,
        icon: Icons.flag_rounded,
        label: 'Drop-off',
      ),
      MapMarkerFactory.car(accent: AppColors.primary),
      MapMarkerFactory.userDot(),
    ).wait;
    return RideMapIcons(
      pickup: pickup,
      dropoff: dropoff,
      car: car,
      userDot: userDot,
    );
  }
}

/// Route lines and camera framing shared by both active-ride maps.
abstract final class RideMapStyle {
  RideMapStyle._();

  static const Color _approachColor = Color(0xFF64748B);

  /// Straight (geodesic) guide lines — not road routes.
  ///
  /// Before the trip starts: a dotted grey "approach" leg driver → pickup and
  /// a dashed trip leg pickup → dropoff. Once [tripStarted]: a solid trip leg
  /// with a white casing, and no approach leg.
  static Set<Polyline> polylines({
    required LatLng? driver,
    required LatLng pickup,
    required LatLng dropoff,
    required bool tripStarted,
  }) =>
      {
        if (!tripStarted && driver != null)
          Polyline(
            polylineId: const PolylineId('approach'),
            points: [driver, pickup],
            color: _approachColor,
            width: 4,
            geodesic: true,
            patterns: [PatternItem.dot, PatternItem.gap(8)],
            zIndex: 1,
          ),
        if (tripStarted)
          Polyline(
            polylineId: const PolylineId('trip_casing'),
            points: [pickup, dropoff],
            color: Colors.white,
            width: 9,
            geodesic: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            zIndex: 2,
          ),
        Polyline(
          polylineId: const PolylineId('trip'),
          points: [pickup, dropoff],
          color: tripStarted
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.75),
          width: 5,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          patterns: tripStarted
              ? const []
              : [PatternItem.dash(18), PatternItem.gap(10)],
          zIndex: 3,
        ),
      };

  /// Animates [controller] so every point in [points] is visible inside the
  /// map's padded area (see `GoogleMap.padding`).
  ///
  /// On Android, bounds updates throw if the map hasn't been laid out yet, so
  /// a failed first attempt is retried once after a short delay.
  static Future<void> fitCamera(
    GoogleMapController controller,
    List<LatLng> points,
  ) async {
    if (points.isEmpty) return;
    final update = CameraUpdate.newLatLngBounds(MapGeo.boundsOf(points), 56);
    try {
      await controller.animateCamera(update);
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      try {
        await controller.animateCamera(update);
      } catch (_) {
        // Map was disposed or still not laid out — leave the camera as is.
      }
    }
  }
}
