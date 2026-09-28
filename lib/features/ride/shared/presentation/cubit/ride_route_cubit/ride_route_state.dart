import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Road paths for the active-ride map. A `null` leg means no road route is
/// available (not fetched yet, or routing failed) — the map then falls back to
/// a straight guide line.
final class RideRouteState extends Equatable {
  const RideRouteState({this.activeLeg, this.tripPreview});

  /// What's left of the leg being driven now: driver → pickup before the
  /// trip, driver → dropoff during it.
  final List<LatLng>? activeLeg;

  /// Pickup → dropoff preview, shown only before the trip starts.
  final List<LatLng>? tripPreview;

  RideRouteState withActiveLeg(List<LatLng>? activeLeg) =>
      RideRouteState(activeLeg: activeLeg, tripPreview: tripPreview);

  RideRouteState withTripPreview(List<LatLng>? tripPreview) =>
      RideRouteState(activeLeg: activeLeg, tripPreview: tripPreview);

  @override
  List<Object?> get props => [activeLeg, tripPreview];
}
