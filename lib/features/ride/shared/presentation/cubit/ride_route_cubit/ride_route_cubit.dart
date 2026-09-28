import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../../core/utils/map_geo.dart';
import '../../../data/routing_repository.dart';
import 'ride_route_state.dart';

/// Keeps the road paths of an active ride up to date as the driver moves.
///
/// Feed it every map update through [update]. Network calls stay rare: the
/// active leg is fetched once per stage and then only trimmed locally as the
/// driver advances; it is re-fetched only when the driver strays off it, and
/// at most once per [_minRefetchInterval].
class RideRouteCubit extends Cubit<RideRouteState> {
  RideRouteCubit(this._repository, {DateTime Function()? clock})
      : _now = clock ?? DateTime.now,
        super(const RideRouteState());

  /// Farther than this from the current route counts as a detour.
  static const double _offRouteMeters = 50;
  static const Duration _minRefetchInterval = Duration(seconds: 15);

  final RoutingRepository _repository;
  final DateTime Function() _now;

  // Active leg (driver → current target).
  LatLng? _target;
  LatLng? _driver;
  List<LatLng>? _activeRoute; // full fetched path; the state holds what's left
  DateTime? _lastFetchAt;
  int _activeRequest = 0;

  // Trip preview (pickup → dropoff).
  (LatLng, LatLng)? _previewEnds;
  int _previewRequest = 0;

  void update({
    required LatLng? driver,
    required LatLng pickup,
    required LatLng dropoff,
    required bool tripStarted,
  }) {
    _updatePreview(tripStarted ? null : (pickup, dropoff));
    _updateActiveLeg(driver, tripStarted ? dropoff : pickup);
  }

  void _updatePreview((LatLng, LatLng)? ends) {
    if (ends == _previewEnds) return;
    _previewEnds = ends;
    final request = ++_previewRequest;
    emit(state.withTripPreview(null));
    if (ends == null) return;

    _fetch(ends.$1, ends.$2).then((route) {
      if (isClosed || request != _previewRequest || route == null) return;
      emit(state.withTripPreview(route));
    });
  }

  void _updateActiveLeg(LatLng? driver, LatLng target) {
    _driver = driver;
    if (target != _target) {
      // New stage: drop the old leg (and any in-flight fetch for it) and
      // fetch the new one right away, bypassing the throttle.
      _target = target;
      _activeRoute = null;
      _lastFetchAt = null;
      _activeRequest++;
      emit(state.withActiveLeg(null));
    }
    if (driver == null) return;

    final route = _activeRoute;
    if (route != null &&
        MapGeo.nearestOnPath(driver, route).distanceMeters <= _offRouteMeters) {
      emit(state.withActiveLeg(MapGeo.remainingPath(driver, route)));
      return;
    }

    final last = _lastFetchAt;
    if (last == null || _now().difference(last) >= _minRefetchInterval) {
      _fetchActiveLeg(driver, target);
    }
  }

  Future<void> _fetchActiveLeg(LatLng from, LatLng to) async {
    // Stamped before the request, so a failing or slow server is also
    // throttled instead of being retried on every GPS fix.
    _lastFetchAt = _now();
    final request = ++_activeRequest;
    final route = await _fetch(from, to);
    if (isClosed || request != _activeRequest || route == null) return;

    _activeRoute = route;
    emit(state.withActiveLeg(MapGeo.remainingPath(_driver ?? from, route)));
  }

  /// Road path [from] → [to], or `null` when routing fails — the map then
  /// keeps its straight-line fallback.
  Future<List<LatLng>?> _fetch(LatLng from, LatLng to) async {
    try {
      return (await _repository.drivingRoute(from, to)).points;
    } catch (e) {
      debugPrint('RideRouteCubit: $e');
      return null;
    }
  }
}
