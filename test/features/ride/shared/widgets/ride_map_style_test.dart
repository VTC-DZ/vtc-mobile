import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rapidoo/features/ride/shared/widgets/ride_map_style.dart';

void main() {
  const driver = LatLng(36.75, 3.05);
  const pickup = LatLng(36.76, 3.06);
  const dropoff = LatLng(36.70, 3.10);

  Map<String, Polyline> byId(Set<Polyline> polylines) =>
      {for (final p in polylines) p.polylineId.value: p};

  group('RideMapStyle.polylines', () {
    test('before the trip, draws the approach over the trip preview', () {
      final lines = byId(RideMapStyle.polylines(
        const RideMapLegs(approach: [driver, pickup], trip: [pickup, dropoff]),
        tripStarted: false,
      ));

      expect(
        lines.keys.toSet(),
        {'trip', 'trip_casing', 'approach', 'approach_casing'},
      );
      expect(lines['approach']!.zIndex, greaterThan(lines['trip']!.zIndex));
      expect(lines['approach']!.width, greaterThan(lines['trip']!.width));
    });

    test('before the trip without a driver, draws only the trip preview', () {
      final lines = byId(RideMapStyle.polylines(
        const RideMapLegs(approach: null, trip: [pickup, dropoff]),
        tripStarted: false,
      ));

      expect(lines.keys.toSet(), {'trip', 'trip_casing'});
    });

    test('once the trip starts, draws a bolder trip leg', () {
      const legs = RideMapLegs(approach: null, trip: [driver, dropoff]);
      final started = byId(RideMapStyle.polylines(legs, tripStarted: true));
      final preview = byId(RideMapStyle.polylines(legs, tripStarted: false));

      expect(started.keys.toSet(), {'trip', 'trip_casing'});
      expect(started['trip']!.width, greaterThan(preview['trip']!.width));
    });

    test('every line is solid, opaque and narrower than its casing', () {
      for (final tripStarted in [false, true]) {
        final lines = byId(RideMapStyle.polylines(
          const RideMapLegs(
            approach: [driver, pickup],
            trip: [pickup, dropoff],
          ),
          tripStarted: tripStarted,
        ));

        for (final line in lines.values) {
          expect(line.patterns, isEmpty, reason: line.polylineId.value);
          expect(line.color.a, 1.0, reason: line.polylineId.value);
        }
        for (final id in ['trip', 'approach']) {
          final casing = lines['${id}_casing']!;
          expect(casing.width, greaterThan(lines[id]!.width));
          expect(casing.zIndex, lessThan(lines[id]!.zIndex));
        }
      }
    });
  });
}
