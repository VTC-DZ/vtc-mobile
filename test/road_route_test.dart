import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:khfif_drif/features/ride/shared/data/models/road_route.dart';

void main() {
  group('RoadRoute.fromOsrmJson', () {
    test('reads GeoJSON [lng, lat] positions as LatLng(lat, lng)', () {
      final route = RoadRoute.fromOsrmJson(const {
        'code': 'Ok',
        'routes': [
          {
            'distance': 1234.5,
            'duration': 180,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [3.0588, 36.7538],
                [3.06, 36.76],
              ],
            },
          },
        ],
      });

      expect(route.points, const [
        LatLng(36.7538, 3.0588),
        LatLng(36.76, 3.06),
      ]);
      expect(route.distanceMeters, 1234.5);
      expect(route.durationSeconds, 180);
    });

    test('throws when OSRM found no route', () {
      expect(
        () => RoadRoute.fromOsrmJson(const {'code': 'NoRoute', 'routes': []}),
        throwsFormatException,
      );
    });
  });
}
