import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/cancel_ride_dialog.dart';
import '../../../../ride/driver/data/models/ride_socket_event.dart';
import '../../../passenger/data/models/passenger_ride_models.dart';
import '../cubit/passenger_active_ride_cubit/passenger_active_ride_cubit.dart';
import '../cubit/passenger_active_ride_cubit/passenger_active_ride_state.dart';

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
                _StateBadge(rideState: rideState),
                SizedBox(height: 20.h),
                _DriverCard(driver: ride.driver),
                SizedBox(height: 16.h),
                _LiveMapCard(
                  driverLat: driverLat,
                  driverLng: driverLng,
                  ownPosition: ownPosition,
                ),
                SizedBox(height: 16.h),
                _FareCard(finalFare: ride.finalFare),
              ],
            ),
          ),
        ),
        if (canCancel)
          Padding(
            padding: EdgeInsets.fromLTRB(
              20.w,
              8.h,
              20.w,
              MediaQuery.of(context).padding.bottom + 16.h,
            ),
            child: TextButton(
              onPressed: () async {
                final reason = await showCancelRideDialog(context);
                if (reason != null && context.mounted) {
                  context.read<PassengerActiveRideCubit>().cancelRide(reason);
                }
              },
              child: Text(
                'Cancel Ride',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.rideState});

  final RideState? rideState;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (rideState) {
      RideState.accepted => ('Driver is on the way', AppColors.primary),
      RideState.arrived => ('Driver has arrived', Colors.orange),
      RideState.inProgress => ('Ride in progress', Colors.green),
      _ => ('Waiting...', AppColors.textSecondary(context)),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10.w, color: color),
          SizedBox(width: 10.w),
          Text(
            label,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final DriverInRide driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Driver',
            style: AppTextStyles.labelMedium(context).copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 28.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullName,
                      style: AppTextStyles.bodyLarge(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${driver.vehicleModel} · ${driver.vehiclePlate}',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveMapCard extends StatefulWidget {
  const _LiveMapCard({
    required this.driverLat,
    required this.driverLng,
    required this.ownPosition,
  });

  final double? driverLat;
  final double? driverLng;
  final Position? ownPosition;

  @override
  State<_LiveMapCard> createState() => _LiveMapCardState();
}

class _LiveMapCardState extends State<_LiveMapCard> {
  final _mapController = MapController();

  @override
  void didUpdateWidget(_LiveMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lat = widget.driverLat;
    final lng = widget.driverLng;
    // Only animate when the map was already on screen (old coords non-null).
    // If old coords were null we were showing the placeholder — FlutterMap
    // hasn't rendered yet, so calling move() would throw.
    if (lat != null &&
        lng != null &&
        oldWidget.driverLat != null &&
        oldWidget.driverLng != null &&
        (oldWidget.driverLat != lat || oldWidget.driverLng != lng)) {
      _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.driverLat;
    final lng = widget.driverLng;

    if (lat == null || lng == null) {
      return Container(
        height: 250.h,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderDefault(context)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_searching,
                  color: AppColors.textSecondary(context), size: 32.w),
              SizedBox(height: 8.h),
              Text(
                'Waiting for driver location…',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final driverPoint = LatLng(lat, lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: 250.h,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: driverPoint,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'khfif_drif',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: driverPoint,
                  child: const Icon(Icons.directions_car,
                      color: Colors.blue, size: 32),
                ),
                if (widget.ownPosition != null)
                  Marker(
                    point: LatLng(
                      widget.ownPosition!.latitude,
                      widget.ownPosition!.longitude,
                    ),
                    child: const Icon(Icons.person_pin_circle,
                        color: Colors.green, size: 32),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  const _FareCard({required this.finalFare});

  final int finalFare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Agreed Fare',
            style: AppTextStyles.bodyMedium(context),
          ),
          Text(
            '$finalFare DZD',
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
