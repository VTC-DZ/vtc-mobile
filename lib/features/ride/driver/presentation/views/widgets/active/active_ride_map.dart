import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../../../core/utils/map_geo.dart';
import '../../../../../../../core/utils/map_gestures.dart';
import '../../../../../../../core/widgets/app_toast.dart';
import '../../../../../shared/presentation/cubit/ride_route_cubit/ride_route_cubit.dart';
import '../../../../../shared/presentation/cubit/ride_route_cubit/ride_route_state.dart';
import '../../../../../shared/widgets/ride_map_style.dart';
import '../../../../data/models/driver_ride_models.dart';
import '../../../../../passenger/presentation/views/widgets/location/map_button.dart';

/// Full-screen live map for the driver's active ride. Shows pickup and dropoff
/// pins, the driver's own GPS position as a car that turns with its heading,
/// and stage-aware road routes (from the ambient [RideRouteCubit]), with
/// built-in camera controls.
class ActiveRideMap extends StatefulWidget {
  const ActiveRideMap({
    super.key,
    required this.ride,
    required this.driverPosition,
  });

  final ActiveDriverRideResponse ride;
  final Position? driverPosition;

  @override
  State<ActiveRideMap> createState() => _ActiveRideMapState();
}

class _ActiveRideMapState extends State<ActiveRideMap> {
  /// GPS headings are only trusted above walking speed; below it they jitter.
  static const double _minHeadingSpeed = 1; // m/s
  /// Minimum movement before a bearing is derived from consecutive fixes.
  static const double _minBearingDistance = 5; // m

  GoogleMapController? _mapController;
  RideMapIcons? _icons;
  double _heading = 0;
  LatLng? _lastBearingPoint;
  bool _fittedWithDriver = false;

  bool get _tripStarted =>
      widget.ride.state == ActiveDriverRideState.inProgress;

  LatLng get _pickup => LatLng(widget.ride.pickup.lat, widget.ride.pickup.lng);

  LatLng get _dropoff =>
      LatLng(widget.ride.dropoff.lat, widget.ride.dropoff.lng);

  LatLng? get _driver {
    final p = widget.driverPosition;
    return p == null ? null : LatLng(p.latitude, p.longitude);
  }

  @override
  void initState() {
    super.initState();
    _updateHeading();
    _syncRoute();
    RideMapIcons.load().then((icons) {
      if (mounted) setState(() => _icons = icons);
    });
  }

  @override
  void didUpdateWidget(ActiveRideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final moved = widget.driverPosition != oldWidget.driverPosition;
    final stageChanged = widget.ride.state != oldWidget.ride.state;
    if (moved) _updateHeading();
    if (moved || stageChanged) _syncRoute();

    // Reframe when the first GPS fix arrives, and when the trip starts (the
    // target switches from pickup to dropoff).
    final gotFirstFix = !_fittedWithDriver && widget.driverPosition != null;
    if (gotFirstFix || stageChanged) _fitRoute();
  }

  void _syncRoute() {
    context.read<RideRouteCubit>().update(
          driver: _driver,
          pickup: _pickup,
          dropoff: _dropoff,
          tripStarted: _tripStarted,
        );
  }

  RideMapLegs _legs(RideRouteState route) => RideMapStyle.resolveLegs(
        route,
        driver: _driver,
        pickup: _pickup,
        dropoff: _dropoff,
        tripStarted: _tripStarted,
      );

  void _updateHeading() {
    final position = widget.driverPosition;
    if (position == null) return;
    final point = LatLng(position.latitude, position.longitude);
    if (position.heading >= 0 && position.speed > _minHeadingSpeed) {
      _heading = position.heading;
      _lastBearingPoint = point;
      return;
    }
    final last = _lastBearingPoint;
    if (last == null) {
      _lastBearingPoint = point;
    } else if (MapGeo.distanceMeters(last, point) > _minBearingDistance) {
      _heading = MapGeo.bearingBetween(last, point);
      _lastBearingPoint = point;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Frames the leg that matters now: driver → pickup before the trip,
  /// driver → dropoff during it (pickup → dropoff while GPS is unknown).
  /// Frames the whole road path, which can bulge past its endpoints.
  void _fitRoute() {
    final controller = _mapController;
    if (controller == null) return;
    _fittedWithDriver = _driver != null;
    RideMapStyle.fitCamera(
      controller,
      _legs(context.read<RideRouteCubit>().state).focus,
    );
  }

  /// Recenters the camera on the driver's own live GPS position (already
  /// streamed by the parent view). Keeps the current zoom level.
  void _goToDriverLocation() {
    final driver = _driver;
    if (driver == null) {
      AppToast.error('Locating your position, please wait.');
      return;
    }
    _mapController?.animateCamera(CameraUpdate.newLatLng(driver));
  }

  void _zoomIn() => _mapController?.animateCamera(CameraUpdate.zoomIn());

  void _zoomOut() => _mapController?.animateCamera(CameraUpdate.zoomOut());

  @override
  Widget build(BuildContext context) {
    final icons = _icons;
    final driver = _driver;
    final media = MediaQuery.of(context);

    return Stack(
      children: [
        BlocConsumer<RideRouteCubit, RideRouteState>(
          // Reframe once when a stage's road path first arrives.
          listenWhen: (previous, current) =>
              previous.activeLeg == null && current.activeLeg != null,
          listener: (context, _) => _fitRoute(),
          builder: (context, route) => GoogleMap(
            gestureRecognizers: mapGestureRecognizers,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitRoute();
            },
            // Center on the passenger (pickup) until the camera is framed.
            initialCameraPosition: CameraPosition(target: _pickup, zoom: 15),
            // Keep framed content clear of the back button and bottom sheet.
            padding: EdgeInsets.only(
              top: media.padding.top + 56.h,
              bottom: media.size.height * 0.42,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            polylines: RideMapStyle.polylines(
              _legs(route),
              tripStarted: _tripStarted,
            ),
            markers: {
              if (icons != null) ...{
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: _pickup,
                  icon: icons.pickup.descriptor,
                  anchor: icons.pickup.anchor,
                  // The passenger is on board once the trip starts.
                  alpha: _tripStarted ? 0.5 : 1,
                  zIndexInt: 1,
                ),
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: _dropoff,
                  icon: icons.dropoff.descriptor,
                  anchor: icons.dropoff.anchor,
                  zIndexInt: 1,
                ),
                // Driver's own GPS position
                if (driver != null)
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: driver,
                    icon: icons.car,
                    anchor: const Offset(0.5, 0.5),
                    flat: true,
                    rotation: _heading,
                    zIndexInt: 2,
                  ),
              },
            },
          ),
        ),

        // Map controls: route overview, current location, zoom (top-right)
        Positioned(
          top: media.padding.top + 8.h,
          right: 16.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapButton(
                icon: Icons.alt_route_rounded,
                onTap: _fitRoute,
              ),
              SizedBox(height: 12.h),
              MapButton(
                icon: Icons.my_location_rounded,
                onTap: _goToDriverLocation,
              ),
              SizedBox(height: 12.h),
              MapButton(
                icon: Icons.add_rounded,
                onTap: _zoomIn,
              ),
              SizedBox(height: 12.h),
              MapButton(
                icon: Icons.remove_rounded,
                onTap: _zoomOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
