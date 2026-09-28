import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/map_geo.dart';
import '../../../../../../../core/utils/map_gestures.dart';
import '../../../../../driver/data/models/ride_socket_event.dart';
import '../../../../../shared/models/shared_ride_models.dart';
import '../../../../../shared/presentation/cubit/ride_route_cubit/ride_route_cubit.dart';
import '../../../../../shared/presentation/cubit/ride_route_cubit/ride_route_state.dart';
import '../../../../../shared/widgets/ride_map_style.dart';

/// Full-screen capable live map. Sizes to whatever its parent gives it.
/// Caller is responsible for bounding the widget (e.g. Positioned.fill or SizedBox).
///
/// Shows pickup/dropoff pins, the driver as a car turned toward its direction
/// of travel, the passenger's own position, and stage-aware road routes (from
/// the ambient [RideRouteCubit]).
class LiveMapCard extends StatefulWidget {
  const LiveMapCard({
    super.key,
    required this.driverLat,
    required this.driverLng,
    required this.ownPosition,
    this.rideState,
    this.pickup,
    this.dropoff,
    this.driverLabel,
  });

  final double? driverLat;
  final double? driverLng;
  final Position? ownPosition;
  final RideState? rideState;
  final CoordinatePoint? pickup;
  final CoordinatePoint? dropoff;
  final String? driverLabel;

  @override
  State<LiveMapCard> createState() => _LiveMapCardState();
}

class _LiveMapCardState extends State<LiveMapCard> {
  /// Minimum driver movement before the car is turned toward the new point —
  /// below this, GPS jitter would make it spin in place.
  static const double _minBearingDistance = 3; // m

  GoogleMapController? _mapController;
  RideMapIcons? _icons;
  double _driverBearing = 0;
  bool _fittedWithDriver = false;

  bool get _tripStarted => widget.rideState == RideState.inProgress;

  LatLng? get _driver {
    final lat = widget.driverLat;
    final lng = widget.driverLng;
    return lat == null || lng == null ? null : LatLng(lat, lng);
  }

  LatLng? get _pickup => widget.pickup == null
      ? null
      : LatLng(widget.pickup!.lat, widget.pickup!.lng);

  LatLng? get _dropoff => widget.dropoff == null
      ? null
      : LatLng(widget.dropoff!.lat, widget.dropoff!.lng);

  @override
  void initState() {
    super.initState();
    _syncRoute();
    RideMapIcons.load().then((icons) {
      if (mounted) setState(() => _icons = icons);
    });
  }

  @override
  void didUpdateWidget(LiveMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final driver = _driver;
    final oldLat = oldWidget.driverLat;
    final oldLng = oldWidget.driverLng;
    if (driver != null && oldLat != null && oldLng != null) {
      final previous = LatLng(oldLat, oldLng);
      if (MapGeo.distanceMeters(previous, driver) > _minBearingDistance) {
        _driverBearing = MapGeo.bearingBetween(previous, driver);
      }
      if (previous != driver) _keepDriverInView(driver);
    }
    _syncRoute();

    // Reframe when the driver first appears, and when the trip starts (the
    // target switches from pickup to dropoff).
    final gotFirstFix = !_fittedWithDriver && driver != null;
    final stageChanged = widget.rideState != oldWidget.rideState;
    if (gotFirstFix || stageChanged) _fitRoute();
  }

  /// Road routing needs both ride ends; until then nothing is drawn.
  void _syncRoute() {
    final pickup = _pickup;
    final dropoff = _dropoff;
    if (pickup == null || dropoff == null) return;
    context.read<RideRouteCubit>().update(
          driver: _driver,
          pickup: pickup,
          dropoff: dropoff,
          tripStarted: _tripStarted,
        );
  }

  RideMapLegs? _legs(RideRouteState route) {
    final pickup = _pickup;
    final dropoff = _dropoff;
    if (pickup == null || dropoff == null) return null;
    return RideMapStyle.resolveLegs(
      route,
      driver: _driver,
      pickup: pickup,
      dropoff: dropoff,
      tripStarted: _tripStarted,
    );
  }

  /// Follows the driver only when they leave the visible area, so the camera
  /// doesn't fight a passenger who panned or zoomed the map.
  Future<void> _keepDriverInView(LatLng driver) async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      final region = await controller.getVisibleRegion();
      if (!region.contains(driver)) {
        await controller.animateCamera(CameraUpdate.newLatLng(driver));
      }
    } catch (_) {
      // Map disposed mid-update.
    }
  }

  /// Frames the leg that matters now: driver → pickup before the trip,
  /// driver → dropoff during it (pickup → dropoff while the driver is unknown).
  /// Frames the whole road path, which can bulge past its endpoints.
  void _fitRoute() {
    final controller = _mapController;
    if (controller == null) return;
    final driver = _driver;
    _fittedWithDriver = driver != null;
    final legs = _legs(context.read<RideRouteCubit>().state);
    RideMapStyle.fitCamera(
      controller,
      legs?.focus ?? [driver, _pickup, _dropoff].whereType<LatLng>().toList(),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icons = _icons;
    final driver = _driver;
    final pickup = _pickup;
    final dropoff = _dropoff;
    final own = widget.ownPosition;
    final media = MediaQuery.of(context);
    final controlsTop = media.padding.top + 76.h;
    final initialTarget = driver ?? pickup ?? const LatLng(36.7538, 3.0588);

    return Stack(
      children: [
        BlocConsumer<RideRouteCubit, RideRouteState>(
          // Reframe once when a stage's road path first arrives.
          listenWhen: (previous, current) =>
              previous.activeLeg == null && current.activeLeg != null,
          listener: (context, _) => _fitRoute(),
          builder: (context, route) => GoogleMap(
            gestureRecognizers: mapGestureRecognizers,
            // setState so _MapZoomButtons receives the controller.
            onMapCreated: (controller) {
              setState(() => _mapController = controller);
              _fitRoute();
            },
            initialCameraPosition:
                CameraPosition(target: initialTarget, zoom: 14),
            // Keep framed content clear of the status badge and bottom sheet.
            padding: EdgeInsets.only(
              top: controlsTop,
              bottom: media.size.height * 0.42,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            polylines: switch (_legs(route)) {
              final legs? =>
                RideMapStyle.polylines(legs, tripStarted: _tripStarted),
              null => const {},
            },
            markers: {
              if (icons != null) ...{
                if (pickup != null)
                  Marker(
                    markerId: const MarkerId('pickup'),
                    position: pickup,
                    icon: icons.pickup.descriptor,
                    anchor: icons.pickup.anchor,
                    // The passenger is on board once the trip starts.
                    alpha: _tripStarted ? 0.5 : 1,
                    zIndexInt: 1,
                  ),
                if (dropoff != null)
                  Marker(
                    markerId: const MarkerId('dropoff'),
                    position: dropoff,
                    icon: icons.dropoff.descriptor,
                    anchor: icons.dropoff.anchor,
                    zIndexInt: 1,
                  ),
                // Passenger's own position ("you"). Hidden during the trip —
                // they're in the car.
                if (own != null && !_tripStarted)
                  Marker(
                    markerId: const MarkerId('own'),
                    position: LatLng(own.latitude, own.longitude),
                    icon: icons.userDot,
                    anchor: const Offset(0.5, 0.5),
                    zIndexInt: 2,
                  ),
                // Driver's live position
                if (driver != null)
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: driver,
                    icon: icons.car,
                    anchor: const Offset(0.5, 0.5),
                    flat: true,
                    rotation: _driverBearing,
                    zIndexInt: 3,
                    infoWindow:
                        InfoWindow(title: widget.driverLabel ?? 'Driver'),
                  ),
              },
            },
          ),
        ),
        if (driver == null)
          Positioned(
            top: controlsTop,
            left: 0,
            right: 0,
            child: const Center(child: _WaitingForDriverPill()),
          ),
        Positioned(
          right: 12.w,
          top: controlsTop + (driver == null ? 48.h : 0),
          child: _MapZoomButtons(
            controller: _mapController,
            onFitRoute: _fitRoute,
          ),
        ),
      ],
    );
  }
}

class _WaitingForDriverPill extends StatelessWidget {
  const _WaitingForDriverPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12.w,
            height: 12.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Waiting for driver location…',
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapZoomButtons extends StatelessWidget {
  const _MapZoomButtons({required this.controller, required this.onFitRoute});

  final GoogleMapController? controller;
  final VoidCallback onFitRoute;

  void _zoom(double delta) {
    controller?.animateCamera(CameraUpdate.zoomBy(delta));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomBtn(
            icon: Icons.alt_route_rounded,
            onTap: onFitRoute,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderDefault(context),
          ),
          _ZoomBtn(
            icon: Icons.add_rounded,
            onTap: () => _zoom(1),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderDefault(context),
          ),
          _ZoomBtn(
            icon: Icons.remove_rounded,
            onTap: () => _zoom(-1),
          ),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40.w,
        height: 40.w,
        child: Icon(icon, size: 20.w, color: AppColors.text(context)),
      ),
    );
  }
}
