import 'dart:convert';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Small spherical-geometry helpers for map markers, camera framing and
/// route snapping.
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

  /// Closest point to [point] on the polyline [path], with the index of the
  /// segment it lies on (`path[segmentIndex] → path[segmentIndex + 1]`) and
  /// its distance in meters.
  ///
  /// Uses a local flat-earth projection around [point] — accurate to well
  /// under a meter at city scale, which is all route snapping needs.
  static ({int segmentIndex, LatLng snapped, double distanceMeters})
      nearestOnPath(LatLng point, List<LatLng> path) {
    assert(path.isNotEmpty, 'nearestOnPath needs at least one point');
    if (path.length == 1) {
      return (
        segmentIndex: 0,
        snapped: path.first,
        distanceMeters: distanceMeters(point, path.first),
      );
    }

    // Meters per degree around [point]; [point] itself is the origin.
    const metersPerDegLat = _earthRadiusMeters * math.pi / 180;
    final metersPerDegLng = metersPerDegLat * math.cos(_rad(point.latitude));
    double x(LatLng p) => (p.longitude - point.longitude) * metersPerDegLng;
    double y(LatLng p) => (p.latitude - point.latitude) * metersPerDegLat;

    var bestIndex = 0;
    var bestT = 0.0;
    var bestDistanceSq = double.infinity;
    for (var i = 0; i < path.length - 1; i++) {
      final ax = x(path[i]);
      final ay = y(path[i]);
      final dx = x(path[i + 1]) - ax;
      final dy = y(path[i + 1]) - ay;
      final lengthSq = dx * dx + dy * dy;
      // Parameter of the origin's projection onto a→b, clamped to the segment.
      final t = lengthSq == 0
          ? 0.0
          : (-(ax * dx + ay * dy) / lengthSq).clamp(0.0, 1.0);
      final cx = ax + t * dx;
      final cy = ay + t * dy;
      final distanceSq = cx * cx + cy * cy;
      if (distanceSq < bestDistanceSq) {
        bestDistanceSq = distanceSq;
        bestIndex = i;
        bestT = t;
      }
    }

    final a = path[bestIndex];
    final b = path[bestIndex + 1];
    return (
      segmentIndex: bestIndex,
      snapped: LatLng(
        a.latitude + bestT * (b.latitude - a.latitude),
        a.longitude + bestT * (b.longitude - a.longitude),
      ),
      distanceMeters: math.sqrt(bestDistanceSq),
    );
  }

  /// The part of [path] still ahead of [position]: starts at [position]
  /// snapped onto the path and drops everything already travelled.
  static List<LatLng> remainingPath(LatLng position, List<LatLng> path) {
    if (path.length < 2) return path;
    final nearest = nearestOnPath(position, path);
    return [nearest.snapped, ...path.skip(nearest.segmentIndex + 1)];
  }

  /// Points of a GeoJSON `LineString` — given as the geometry itself, a
  /// `Feature` wrapping it, or either one encoded as a JSON string. GeoJSON
  /// positions are `[lng, lat]`. Returns `null` for anything else, or when
  /// fewer than two positions parse.
  static List<LatLng>? lineStringPoints(Object? geoJson) {
    var json = geoJson;
    if (json is String) {
      try {
        json = jsonDecode(json);
      } on FormatException {
        return null;
      }
    }
    if (json is! Map) return null;
    if (json['type'] == 'Feature') json = json['geometry'];
    if (json is! Map || json['type'] != 'LineString') return null;
    final coordinates = json['coordinates'];
    if (coordinates is! List) return null;

    final points = <LatLng>[];
    for (final c in coordinates) {
      if (c is! List || c.length < 2) return null;
      final (lng, lat) = (c[0], c[1]);
      if (lng is! num || lat is! num) return null;
      points.add(LatLng(lat.toDouble(), lng.toDouble()));
    }
    return points.length < 2 ? null : points;
  }

  static double _rad(double deg) => deg * math.pi / 180;

  static double _deg(double rad) => rad * 180 / math.pi;
}
