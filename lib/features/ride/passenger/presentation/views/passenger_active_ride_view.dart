import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/cancel_ride_dialog.dart';
import '../../../../ride/driver/data/models/ride_socket_event.dart';
import '../../../shared/widgets/active_ride/active_ride_cancel_button.dart';
import '../../../shared/widgets/active_ride/active_ride_sheet.dart';
import '../../../shared/widgets/active_ride/ride_fare_row.dart';
import '../../../shared/widgets/active_ride/ride_stage_header.dart';
import '../../../shared/widgets/ride_detail/ride_detail_addresses_card.dart';
import '../../../shared/widgets/ride_detail/ride_detail_person_card.dart';
import '../cubit/passenger_active_ride_cubit/passenger_active_ride_cubit.dart';
import '../cubit/passenger_active_ride_cubit/passenger_active_ride_state.dart';
import 'widgets/active_ride/live_map_card.dart';

class PassengerActiveRideView extends StatefulWidget {
  const PassengerActiveRideView({super.key});

  @override
  State<PassengerActiveRideView> createState() =>
      _PassengerActiveRideViewState();
}

class _PassengerActiveRideViewState extends State<PassengerActiveRideView> {
  StreamSubscription<Position>? _positionSub;
  Position? _ownPosition;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  Future<void> _startLocationUpdates() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((pos) {
      if (mounted) setState(() => _ownPosition = pos);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PassengerActiveRideCubit, PassengerActiveRideState>(
      listenWhen: (prev, curr) =>
          curr.status == PassengerActiveRideStatus.completed ||
          curr.status == PassengerActiveRideStatus.cancelled ||
          curr.status == PassengerActiveRideStatus.actionFailure,
      listener: (context, state) {
        switch (state.status) {
          case PassengerActiveRideStatus.actionFailure:
            AppToast.error(state.errorMessage);
          case PassengerActiveRideStatus.completed:
            AppToast.success('Ride completed!');
            context.go(RouteNames.passengerHome);
          case PassengerActiveRideStatus.cancelled:
            AppToast.warning('Ride was cancelled');
            context.go(RouteNames.passengerHome);
          default:
            break;
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: switch (state.status) {
            PassengerActiveRideStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
            PassengerActiveRideStatus.failure => Center(
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
              ),
            _ => state.ride == null
                ? const SizedBox.shrink()
                : _RideBody(state: state, ownPosition: _ownPosition),
          },
        );
      },
    );
  }
}

class _RideBody extends StatelessWidget {
  const _RideBody({required this.state, required this.ownPosition});

  final PassengerActiveRideState state;
  final Position? ownPosition;

  Future<void> _cancel(BuildContext context) async {
    final reason = await showCancelRideDialog(context);
    if (reason != null && context.mounted) {
      context.read<PassengerActiveRideCubit>().cancelRide(reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = state.ride!;
    final rideState = state.rideState;
    final canCancel =
        rideState == RideState.accepted || rideState == RideState.arrived;
    final double? driverLat = state.driverLat ?? ride.driver.currentLat;
    final double? driverLng = state.driverLng ?? ride.driver.currentLng;
    final pickup = ride.pickup;
    final dropoff = ride.dropoff;

    final (title, color, step) = switch (rideState) {
      RideState.arrived => ('Driver has arrived', rideStageArrivedColor, 1),
      RideState.inProgress => (
          'On the way to drop-off',
          rideStageInTripColor,
          2,
        ),
      _ => ('Driver is on the way', AppColors.primary, 0),
    };
    final (subtitle, distanceSuffix) = switch (rideState) {
      RideState.arrived => ('Meet them at the pickup', null),
      RideState.inProgress => (dropoff?.address, 'to drop-off'),
      _ => (pickup?.address, 'away'),
    };

    return Stack(
      children: [
        // Full-screen live map
        Positioned.fill(
          child: LiveMapCard(
            driverLat: driverLat,
            driverLng: driverLng,
            ownPosition: ownPosition,
            rideState: rideState,
            pickup: pickup,
            dropoff: dropoff,
            driverLabel:
                ride.driver.fullName.split(' ').firstOrNull ?? 'Driver',
          ),
        ),
        ActiveRideSheet(
          header: RideStageHeader(
            title: title,
            color: color,
            step: step,
            subtitle: subtitle,
            distanceSuffix: distanceSuffix,
          ),
          children: [
            RideDetailPersonCard(
              role: 'Your driver',
              name: ride.driver.fullName.trim().isEmpty
                  ? 'Driver'
                  : ride.driver.fullName,
              phone: ride.driver.phone,
              vehicleModel: ride.driver.vehicleModel,
              vehiclePlate: ride.driver.vehiclePlate,
            ),
            if (pickup != null && dropoff != null)
              RideDetailAddressesCard(
                pickup: pickup.address,
                dropoff: dropoff.address,
                pickupTime: ride.startedAt,
              ),
            RideFareRow(fare: ride.finalFare),
            if (canCancel)
              ActiveRideCancelButton(onPressed: () => _cancel(context)),
          ],
        ),
      ],
    );
  }
}
