import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../ride/driver/data/models/ride_socket_event.dart';
import '../cubit/passenger_active_ride_cubit/passenger_active_ride_cubit.dart';
import '../cubit/passenger_active_ride_cubit/passenger_active_ride_state.dart';
import 'widgets/active_ride/cancel_ride_button.dart';
import 'widgets/active_ride/driver_card.dart';
import 'widgets/active_ride/fare_card.dart';
import 'widgets/active_ride/live_map_card.dart';
import 'widgets/active_ride/state_badge.dart';

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
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
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
          curr.status == PassengerActiveRideStatus.cancelled,
      listener: (context, state) {
        final message = state.status == PassengerActiveRideStatus.completed
            ? 'Ride completed!'
            : 'Ride was cancelled';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        context.go(RouteNames.passengerHome);
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          appBar: AppBar(
            backgroundColor: AppColors.background(context),
            automaticallyImplyLeading: false,
            title: Text(
              'Your Ride',
              style: AppTextStyles.headingSmall(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final ride = state.ride!;
    final rideState = state.rideState;
    final canCancel =
        rideState == RideState.accepted || rideState == RideState.arrived;
    final double? driverLat = state.driverLat ?? ride.driver.currentLat;
    final double? driverLng = state.driverLng ?? ride.driver.currentLng;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RideStateBadge(rideState: rideState),
                SizedBox(height: 20.h),
                DriverCard(driver: ride.driver),
                SizedBox(height: 16.h),
                LiveMapCard(
                  driverLat: driverLat,
                  driverLng: driverLng,
                  ownPosition: ownPosition,
                ),
                SizedBox(height: 16.h),
                FareCard(finalFare: ride.finalFare),
              ],
            ),
          ),
        ),
        if (canCancel)
          CancelRideButton(
            onCancel: (reason) =>
                context.read<PassengerActiveRideCubit>().cancelRide(reason),
          ),
      ],
    );
  }
}
