import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:khfif_drif/features/ride/shared/data/models/road_route.dart';
import 'package:khfif_drif/features/ride/shared/data/routing_repository.dart';
import 'package:khfif_drif/features/ride/shared/presentation/cubit/ride_route_cubit/ride_route_cubit.dart';

/// Records every request; answers with a straight [from, to] "road" unless a
/// test takes over via [respond].
class _FakeRoutingRepository extends RoutingRepository {
  final requests = <(LatLng, LatLng)>[];
  Future<RoadRoute> Function(LatLng from, LatLng to)? respond;

  @override
  Future<RoadRoute> drivingRoute(LatLng from, LatLng to) {
    requests.add((from, to));
    return respond?.call(from, to) ??
        Future.value(RoadRoute(
          points: [from, to],
          distanceMeters: 0,
          durationSeconds: 0,
        ));
  }
}

void main() {
  const pickup = LatLng(36.7600, 3.0600);
  const dropoff = LatLng(36.7700, 3.0700);
  const driver = LatLng(36.7500, 3.0500);

  late _FakeRoutingRepository repository;
  late DateTime now;
  late RideRouteCubit cubit;

  void update(LatLng? driverAt, {bool tripStarted = false}) => cubit.update(
        driver: driverAt,
        pickup: pickup,
        dropoff: dropoff,
        tripStarted: tripStarted,
      );

  setUp(() {
    repository = _FakeRoutingRepository();
    now = DateTime(2026, 9, 28, 12);
    cubit = RideRouteCubit(repository, clock: () => now);
  });

  tearDown(() => cubit.close());

  test('first update fetches the approach leg and the trip preview', () async {
    update(driver);
    await pumpEventQueue();

    expect(repository.requests, [(pickup, dropoff), (driver, pickup)]);
    expect(cubit.state.activeLeg, [driver, pickup]);
    expect(cubit.state.tripPreview, [pickup, dropoff]);
  });

  test('moving along the route only trims it — no new request', () async {
    update(driver);
    await pumpEventQueue();
    repository.requests.clear();

    const halfway = LatLng(36.7550, 3.0550);
    update(halfway);

    expect(repository.requests, isEmpty);
    final leg = cubit.state.activeLeg!;
    expect(leg, hasLength(2));
    expect(leg.first.latitude, closeTo(halfway.latitude, 1e-6));
    expect(leg.last, pickup);
  });

  test('going off-route refetches, but at most once per interval', () async {
    update(driver);
    await pumpEventQueue();
    repository.requests.clear();

    const detour = LatLng(36.7500, 3.0600); // ~800 m off the straight leg
    update(detour);
    expect(repository.requests, isEmpty, reason: 'throttled');

    now = now.add(const Duration(seconds: 16));
    update(detour);
    await pumpEventQueue();
    expect(repository.requests, [(detour, pickup)]);
    expect(cubit.state.activeLeg, [detour, pickup]);
  });

  test('starting the trip switches the leg to the dropoff immediately',
      () async {
    update(driver);
    await pumpEventQueue();
    repository.requests.clear();

    update(pickup, tripStarted: true);
    expect(repository.requests, [(pickup, dropoff)], reason: 'no throttle');
    expect(cubit.state.tripPreview, isNull);

    await pumpEventQueue();
    expect(cubit.state.activeLeg, [pickup, dropoff]);
  });

  test('a response for a previous stage is ignored', () async {
    final approach = Completer<RoadRoute>();
    repository.respond = (from, to) => to == pickup
        ? approach.future
        : Future.value(RoadRoute(
            points: [from, to],
            distanceMeters: 0,
            durationSeconds: 0,
          ));

    update(driver);
    update(pickup, tripStarted: true);
    await pumpEventQueue();
    expect(cubit.state.activeLeg, [pickup, dropoff]);

    approach.complete(const RoadRoute(
      points: [driver, pickup],
      distanceMeters: 0,
      durationSeconds: 0,
    ));
    await pumpEventQueue();
    expect(cubit.state.activeLeg, [pickup, dropoff]);
  });

  test('a routing failure leaves no route and is not retried at once',
      () async {
    repository.respond = (_, __) => Future.error('offline');

    update(driver);
    await pumpEventQueue();
    expect(cubit.state.activeLeg, isNull);
    expect(cubit.state.tripPreview, isNull);

    repository.requests.clear();
    update(const LatLng(36.7501, 3.0501));
    expect(repository.requests, isEmpty);
  });
}
