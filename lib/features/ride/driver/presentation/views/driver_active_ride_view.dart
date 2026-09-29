import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/external_navigation.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../data/models/driver_ride_models.dart';
import '../../../shared/widgets/active_ride/active_ride_cancel_button.dart';
import '../../../shared/widgets/active_ride/active_ride_sheet.dart';
import '../../../shared/widgets/active_ride/ride_fare_row.dart';
import '../../../shared/widgets/active_ride/ride_stage_header.dart';
import '../../../shared/widgets/expiry_indicators.dart';
import '../../../shared/widgets/ride_detail/ride_detail_addresses_card.dart';
import '../../../shared/widgets/ride_detail/ride_detail_person_card.dart';
import '../cubit/driver_active_ride_cubit/driver_active_ride_cubit.dart';
import '../cubit/driver_active_ride_cubit/driver_active_ride_state.dart';
import 'widgets/active/active_ride_map.dart';
import 'widgets/active/floating_back_button.dart';

class DriverActiveRideView extends StatefulWidget {
  const DriverActiveRideView({super.key});

  @override
  State<DriverActiveRideView> createState() => _DriverActiveRideViewState();
}

class _DriverActiveRideViewState extends State<DriverActiveRideView> {
  StreamSubscription<Position>? _positionSub;
  Position? _driverPosition;

  @override
  void initState() {
    super.initState();
    context.read<DriverActiveRideCubit>().loadActiveRide();
    _startLocationUpdates();
  }

  Future<void> _startLocationUpdates() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    _positionSub = Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((pos) {
      if (mounted) setState(() => _driverPosition = pos);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: BlocConsumer<DriverActiveRideCubit, DriverActiveRideState>(
        listenWhen: (prev, curr) =>
            curr.status == DriverActiveRideStatus.cancelled ||
            curr.status == DriverActiveRideStatus.completed ||
            curr.status == DriverActiveRideStatus.actionFailure,
        listener: (context, state) {
          switch (state.status) {
            case DriverActiveRideStatus.cancelled:
              AppToast.warning('Ride was cancelled');
              context.go(RouteNames.driverHome);
            case DriverActiveRideStatus.completed:
              AppToast.success(
                'Ride completed — ${state.completedFare ?? 0} DZD',
              );
              context.go(RouteNames.driverHome);
            case DriverActiveRideStatus.actionFailure:
              AppToast.error(state.errorMessage);
            default:
              break;
          }
        },
        builder: (context, state) {
          if (state.status == DriverActiveRideStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == DriverActiveRideStatus.noActiveRide) {
            return Center(
              child: Text(
                'No active ride',
                style: AppTextStyles.bodyMedium(context)
                    .copyWith(color: AppColors.textSecondary(context)),
              ),
            );
          }
          if (state.status == DriverActiveRideStatus.failure) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  state.errorMessage.isEmpty
                      ? 'Could not load ride'
                      : state.errorMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context)
                      .copyWith(color: AppColors.textSecondary(context)),
                ),
              ),
            );
          }

          final ride = state.ride;
          if (ride == null) return const SizedBox.shrink();

          return _RideStack(
            ride: ride,
            driverPosition: _driverPosition,
            isTransitioning:
                state.status == DriverActiveRideStatus.transitioning,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RideStack extends StatelessWidget {
  const _RideStack({
    required this.ride,
    required this.driverPosition,
    required this.isTransitioning,
  });

  final ActiveDriverRideResponse ride;
  final Position? driverPosition;
  final bool isTransitioning;

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: const Text(
          'The passenger will be notified and the ride will end.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep ride'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel ride'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context
          .read<DriverActiveRideCubit>()
          .cancelRide(CancelReason.driverVehicleIssue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final cubit = context.read<DriverActiveRideCubit>();
    final canCancel = ride.state == ActiveDriverRideState.accepted ||
        ride.state == ActiveDriverRideState.arrived;

    final (title, color, step) = switch (ride.state) {
      ActiveDriverRideState.arrived => (
          'Waiting for passenger',
          rideStageArrivedColor,
          1,
        ),
      ActiveDriverRideState.inProgress => (
          'Heading to drop-off',
          rideStageInTripColor,
          2,
        ),
      _ => ('Heading to pickup', AppColors.primary, 0),
    };
    final (subtitle, distanceSuffix) = switch (ride.state) {
      ActiveDriverRideState.arrived => ('You are at the pickup', null),
      ActiveDriverRideState.inProgress => (ride.dropoff.address, 'to drop-off'),
      _ => (ride.pickup.address, 'away'),
    };

    final (actionLabel, onAction) = switch (ride.state) {
      ActiveDriverRideState.accepted => ('Mark arrived', cubit.markArrived),
      ActiveDriverRideState.arrived => ('Start ride', cubit.startRide),
      ActiveDriverRideState.inProgress => ('Complete ride', cubit.completeRide),
      _ => ('', null as VoidCallback?),
    };

    // Where Google Maps should guide the driver. None while arrived — they
    // are already at the pickup.
    final navigationTarget = switch (ride.state) {
      ActiveDriverRideState.accepted => ride.pickup,
      ActiveDriverRideState.inProgress => ride.dropoff,
      _ => null,
    };
    final waitDeadline = ride.state == ActiveDriverRideState.arrived
        ? ride.arrivalWaitDeadline
        : null;

    return Stack(
      children: [
        // Full-screen map with zoom controls built in
        Positioned.fill(
          child: ActiveRideMap(ride: ride, driverPosition: driverPosition),
        ),

        // Floating back button
        Positioned(
          top: topPadding + 8.h,
          left: 16.w,
          child: const FloatingBackButton(),
        ),

        ActiveRideSheet(
          header: RideStageHeader(
            title: title,
            color: color,
            step: step,
            subtitle: subtitle,
            distanceSuffix: distanceSuffix,
            trailing: waitDeadline == null
                ? null
                : ExpiryCountdown(
                    key: ValueKey(waitDeadline),
                    expiresAt: waitDeadline,
                    iconSize: 14,
                    textStyle: AppTextStyles.labelMedium(context),
                  ),
          ),
          children: [
            if (actionLabel.isNotEmpty)
              Row(
                children: [
                  if (navigationTarget case final target?) ...[
                    _NavigateButton(target: target),
                    SizedBox(width: 10.w),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: actionLabel,
                      onPressed: onAction,
                      isLoading: isTransitioning,
                      isEnabled: !isTransitioning,
                    ),
                  ),
                ],
              ),
            RideDetailPersonCard(
              role: 'Your passenger',
              name: ride.passengerFullName.trim().isEmpty
                  ? 'Passenger'
                  : ride.passengerFullName,
              phone: ride.passengerPhone,
            ),
            RideDetailAddressesCard(
              pickup: ride.pickup.address,
              dropoff: ride.dropoff.address,
              pickupTime: ride.startedAt,
            ),
            RideFareRow(fare: ride.finalFare),
            if (canCancel)
              ActiveRideCancelButton(
                enabled: !isTransitioning,
                onPressed: () => _cancel(context),
              ),
          ],
        ),
      ],
    );
  }
}

/// Square outlined button beside the main action that hands turn-by-turn
/// navigation to [target] off to Google Maps.
class _NavigateButton extends StatelessWidget {
  const _NavigateButton({required this.target});

  final CoordinatePoint target;

  Future<void> _navigate() async {
    final opened = await ExternalNavigation.openDirections(
      LatLng(target.lat, target.lng),
    );
    if (!opened) AppToast.error('Could not open Google Maps');
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    return Material(
      color: AppColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: _navigate,
        child: SizedBox(
          width: 56.h,
          height: 56.h,
          child: Icon(
            Icons.navigation_rounded,
            size: 24.w,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
