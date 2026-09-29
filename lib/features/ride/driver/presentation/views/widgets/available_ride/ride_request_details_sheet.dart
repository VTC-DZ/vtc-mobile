import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/map_geo.dart';
import '../../../../../../../core/utils/map_gestures.dart';
import '../../../../../../../core/widgets/app_toast.dart';
import '../../../../data/models/driver_ride_models.dart';
import '../../../../../shared/utils/fare_formatter.dart';
import '../../../../../shared/widgets/map_control_group.dart';
import '../../../../../shared/widgets/ride_map_style.dart';
import '../../../../../shared/widgets/ride_route_card.dart';
import '../../../../../shared/widgets/service_type_chip.dart';
import '../../../cubit/available_rides_cubit/available_rides_cubit.dart';
import '../../../cubit/available_rides_cubit/available_rides_state.dart';
import '../../../../../shared/widgets/expiry_indicators.dart';
import 'ride_request_badges.dart';

/// What the driver chose in the details sheet; `null` means dismissed.
enum RideRequestAction { bid, ignore }

/// Full details for an incoming ride request: a map preview of the route,
/// full addresses, distances, the proposed fare and a live countdown, with the
/// same Ignore / Bid actions as the card.
///
/// Stays in sync with [AvailableRidesCubit]: re-broadcasts refresh the content,
/// and the sheet closes itself once the request expires or leaves the list
/// (taken by another driver, cancelled by the passenger, …).
Future<RideRequestAction?> showRideRequestDetailsSheet(
  BuildContext context, {
  required AvailableRequestCard ride,
}) {
  // Capture the shell-scoped cubit before the modal swaps the context.
  final cubit = context.read<AvailableRidesCubit>();
  return showModalBottomSheet<RideRequestAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _RideRequestDetailsSheet(initial: ride),
    ),
  );
}

class _RideRequestDetailsSheet extends StatefulWidget {
  const _RideRequestDetailsSheet({required this.initial});

  final AvailableRequestCard initial;

  @override
  State<_RideRequestDetailsSheet> createState() =>
      _RideRequestDetailsSheetState();
}

class _RideRequestDetailsSheetState extends State<_RideRequestDetailsSheet> {
  bool _closed = false;

  String get _id => widget.initial.rideRequestId;

  /// Pops exactly once, however many triggers fire (expiry, removal, button).
  void _close([RideRequestAction? action]) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AvailableRidesCubit, AvailableRidesState>(
      listenWhen: (prev, curr) => prev.rides != curr.rides,
      listener: (_, state) {
        if (!state.rides.any((r) => r.rideRequestId == _id)) _close();
      },
      child: BlocSelector<AvailableRidesCubit, AvailableRidesState,
          AvailableRequestCard>(
        selector: (state) =>
            state.rides.where((r) => r.rideRequestId == _id).firstOrNull ??
            widget.initial,
        builder: (context, ride) => _buildSheet(context, ride),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, AvailableRequestCard ride) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DragHandle(),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2.r),
                    child: ExpiryProgressBar(
                      // Restart the countdown if the server moves the deadline.
                      key: ValueKey(ride.expiresAt),
                      expiresAt: ride.expiresAt,
                      barHeight: 4,
                      onExpired: _close,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _RideRequestMap(pickup: ride.pickup, dropoff: ride.dropoff),
                  SizedBox(height: 16.h),
                  _Header(ride: ride),
                  SizedBox(height: 14.h),
                  _FareHero(amount: ride.proposedFare),
                  SizedBox(height: 16.h),
                  RideRouteCard(pickup: ride.pickup, dropoff: ride.dropoff),
                  SizedBox(height: 12.h),
                  _DistanceStats(ride: ride),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderDefault(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20.w,
              12.h,
              20.w,
              MediaQuery.paddingOf(context).bottom + 12.h,
            ),
            child: _Actions(
              onIgnore: () => _close(RideRequestAction.ignore),
              onBid: () => _close(RideRequestAction.bid),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
      child: Center(
        child: Container(
          width: 32.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppColors.borderDefault(context),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
      ),
    );
  }
}

/// Service / vehicle / women-only chips on the left, countdown on the right.
class _Header extends StatelessWidget {
  const _Header({required this.ride});

  final AvailableRequestCard ride;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ServiceTypeChip(serviceType: ride.serviceType),
              if (ride.vehicleCategory != null)
                VehicleCategoryChip(category: ride.vehicleCategory!),
              if (ride.femaleOnly) const FemaleOnlyBadge(),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        ExpiryCountdown(
          key: ValueKey(ride.expiresAt),
          expiresAt: ride.expiresAt,
          iconSize: 14,
          textStyle: AppTextStyles.labelMedium(context),
        ),
      ],
    );
  }
}

class _FareHero extends StatelessWidget {
  const _FareHero({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Passenger's offer",
          style: AppTextStyles.labelSmall(context).copyWith(
            color: AppColors.textSecondary(context),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          '${formatFare(amount)} DZD',
          style: AppTextStyles.headingMedium(context).copyWith(
            fontSize: 28.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

/// One card with "To pickup" (server-provided, optional) and the estimated
/// straight-line trip length, split by a hairline divider.
class _DistanceStats extends StatelessWidget {
  const _DistanceStats({required this.ride});

  final AvailableRequestCard ride;

  @override
  Widget build(BuildContext context) {
    final tripMeters = MapGeo.distanceMeters(
      LatLng(ride.pickup.lat, ride.pickup.lng),
      LatLng(ride.dropoff.lat, ride.dropoff.lng),
    ).round();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault(context)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (ride.distanceMeters != null) ...[
              Expanded(
                child: _Stat(
                  icon: Icons.near_me_rounded,
                  label: 'To pickup',
                  value: formatDistance(ride.distanceMeters!),
                ),
              ),
              VerticalDivider(
                width: 24.w,
                thickness: 1,
                color: AppColors.borderDefault(context),
              ),
            ],
            Expanded(
              child: _Stat(
                icon: Icons.route_rounded,
                label: 'Trip distance',
                value: '≈\u00A0${formatDistance(tripMeters)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.w, color: AppColors.primary),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        // Scale down rather than truncate so the unit is always visible.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextStyles.headingSmall(context).copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onIgnore, required this.onBid});

  final VoidCallback onIgnore;
  final VoidCallback onBid;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.r),
    );
    final minimumSize = Size(0, 48.h);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary(context),
              side: BorderSide(color: AppColors.borderDefault(context)),
              minimumSize: minimumSize,
              shape: shape,
            ),
            onPressed: onIgnore,
            child: Text(
              'Ignore',
              style: AppTextStyles.labelLarge(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              minimumSize: minimumSize,
              shape: shape,
            ),
            onPressed: onBid,
            child: Text(
              'Place bid',
              style: AppTextStyles.labelLarge(context).copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact route preview: pickup and drop-off pins joined by the dashed trip
/// line, the driver's own blue dot, and controls to re-frame the route, jump
/// to the driver's position and zoom.
class _RideRequestMap extends StatefulWidget {
  const _RideRequestMap({required this.pickup, required this.dropoff});

  final CoordinatePoint pickup;
  final CoordinatePoint dropoff;

  @override
  State<_RideRequestMap> createState() => _RideRequestMapState();
}

class _RideRequestMapState extends State<_RideRequestMap> {
  GoogleMapController? _mapController;
  RideMapIcons? _icons;
  bool _locating = false;

  LatLng get _pickup => LatLng(widget.pickup.lat, widget.pickup.lng);

  LatLng get _dropoff => LatLng(widget.dropoff.lat, widget.dropoff.lng);

  @override
  void initState() {
    super.initState();
    RideMapIcons.load().then((icons) {
      if (mounted) setState(() => _icons = icons);
    });
  }

  @override
  void didUpdateWidget(_RideRequestMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final moved = widget.pickup.lat != oldWidget.pickup.lat ||
        widget.pickup.lng != oldWidget.pickup.lng ||
        widget.dropoff.lat != oldWidget.dropoff.lat ||
        widget.dropoff.lng != oldWidget.dropoff.lng;
    if (moved) _fitRoute();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _fitRoute() {
    final controller = _mapController;
    if (controller == null) return;
    RideMapStyle.fitCamera(controller, [_pickup, _dropoff]);
  }

  void _zoomIn() => _mapController?.animateCamera(CameraUpdate.zoomIn());

  void _zoomOut() => _mapController?.animateCamera(CameraUpdate.zoomOut());

  /// Centers the camera on the driver's GPS position, keeping the zoom.
  /// Uses the last known fix when available so the jump feels instant.
  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppToast.error(
            'Location permission is required to show your position.');
        return;
      }
      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
      await _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (_) {
      AppToast.error('Couldn\'t get your location. Please try again.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icons = _icons;

    return SizedBox(
      height: 220.h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            GoogleMap(
              gestureRecognizers: mapGestureRecognizers,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitRoute();
              },
              initialCameraPosition: CameraPosition(target: _pickup, zoom: 14),
              // Pins grow upward from their anchor — leave headroom for them.
              padding: EdgeInsets.only(top: 24.h),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              polylines: RideMapStyle.polylines(
                RideMapLegs(approach: null, trip: [_pickup, _dropoff]),
                tripStarted: false,
              ),
              markers: {
                if (icons != null) ...{
                  Marker(
                    markerId: const MarkerId('pickup'),
                    position: _pickup,
                    icon: icons.pickup.descriptor,
                    anchor: icons.pickup.anchor,
                    zIndexInt: 1,
                  ),
                  Marker(
                    markerId: const MarkerId('dropoff'),
                    position: _dropoff,
                    icon: icons.dropoff.descriptor,
                    anchor: icons.dropoff.anchor,
                    zIndexInt: 1,
                  ),
                },
              },
            ),
            Positioned(
              top: 10.h,
              right: 10.w,
              child: MapControlGroup(
                buttonSize: 36,
                actions: [
                  MapControlAction(
                    icon: Icons.alt_route_rounded,
                    onTap: _fitRoute,
                  ),
                  MapControlAction(
                    icon: Icons.my_location_rounded,
                    onTap: _goToMyLocation,
                    isLoading: _locating,
                  ),
                  MapControlAction(
                    icon: Icons.add_rounded,
                    onTap: _zoomIn,
                  ),
                  MapControlAction(
                    icon: Icons.remove_rounded,
                    onTap: _zoomOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
