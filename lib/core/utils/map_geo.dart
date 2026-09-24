import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Small spherical-geometry helpers for map markers and camera framing.
abstract final class MapGeo {
  MapGeo._();

  static const double _earthRadiusMeters = 6371000;

  /// Initial great-circle bearing from [from] to [to], in degrees clockwise
  /// from north (0–360). Suitable for `Marker.rotation`.
  static double bearingBetween(LatLng from, LatLng to) {
    final lat1 = _rad(from.latitude);
    final lat2 = _rad(to.latitude);
    final dLng = _rad(to.longitude - from.longitude);
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (_deg(math.atan2(y, x)) + 360) % 360;
  }

  /// Haversine distance between [a] and [b], in meters.
  static double distanceMeters(LatLng a, LatLng b) {
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
  }

  /// Smallest bounds containing [points]. When the points are (nearly) the
  /// same, the box is widened to at least [minSpan] degrees on each axis so
  /// the camera doesn't zoom all the way in.
  static LatLngBounds boundsOf(
    Iterable<LatLng> points, {
    double minSpan = 0.004,
  }) {
    assert(points.isNotEmpty, 'boundsOf needs at least one point');
    var south = double.infinity;
    var north = -double.infinity;
    var west = double.infinity;
    var east = -double.infinity;
    for (final p in points) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    if (north - south < minSpan) {
      final mid = (north + south) / 2;
      south = mid - minSpan / 2;
      north = mid + minSpan / 2;
    }
    if (east - west < minSpan) {
      final mid = (east + west) / 2;
      west = mid - minSpan / 2;
      east = mid + minSpan / 2;
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  static double _rad(double deg) => deg * math.pi / 180;

  static double _deg(double rad) => rad * 180 / math.pi;
}
