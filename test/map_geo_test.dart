import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:khfif_drif/core/utils/map_geo.dart';

void main() {
  group('MapGeo.bearingBetween', () {
    const origin = LatLng(0, 0);

    test('cardinal directions', () {
      expect(
          MapGeo.bearingBetween(origin, const LatLng(1, 0)), closeTo(0, 1e-6));
      expect(
          MapGeo.bearingBetween(origin, const LatLng(0, 1)), closeTo(90, 1e-6));
      expect(MapGeo.bearingBetween(origin, const LatLng(-1, 0)),
          closeTo(180, 1e-6));
      expect(MapGeo.bearingBetween(origin, const LatLng(0, -1)),
          closeTo(270, 1e-6));
    });

    test('is always within [0, 360)', () {
      final b = MapGeo.bearingBetween(
        const LatLng(36.75, 3.05),
        const LatLng(36.70, 3.00),
      );
      expect(b, inInclusiveRange(0, 360));
      expect(b, greaterThan(180)); // south-west
    });
  });

  group('MapGeo.distanceMeters', () {
    test('one degree of latitude is ~111 km', () {
      expect(
        MapGeo.distanceMeters(const LatLng(0, 0), const LatLng(1, 0)),
        closeTo(111195, 50),
      );
    });

    test('same point is zero', () {
      const p = LatLng(36.7538, 3.0588);
      expect(MapGeo.distanceMeters(p, p), 0);
    });
  });

  group('MapGeo.boundsOf', () {
    test('contains every point', () {
      const points = [
        LatLng(36.75, 3.05),
        LatLng(36.70, 3.10),
        LatLng(36.72, 3.00),
      ];
      final bounds = MapGeo.boundsOf(points);
      expect(bounds.southwest, const LatLng(36.70, 3.00));
      expect(bounds.northeast, const LatLng(36.75, 3.10));
      for (final p in points) {
        expect(bounds.contains(p), isTrue);
      }
    });

    test('widens a single point to the minimum span', () {
      const p = LatLng(36.75, 3.05);
      final bounds = MapGeo.boundsOf([p], minSpan: 0.004);
      expect(bounds.northeast.latitude - bounds.southwest.latitude,
          closeTo(0.004, 1e-9));
      expect(bounds.northeast.longitude - bounds.southwest.longitude,
          closeTo(0.004, 1e-9));
      expect(bounds.contains(p), isTrue);
    });
  });
}
