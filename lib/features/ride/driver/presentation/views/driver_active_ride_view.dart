import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/router/route_names.dart';
import '../../data/models/driver_ride_models.dart';
import '../cubit/driver_active_ride_cubit/driver_active_ride_cubit.dart';
import '../cubit/driver_active_ride_cubit/driver_active_ride_state.dart';

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
      appBar: AppBar(title: const Text('Active Ride')),
      body: BlocConsumer<DriverActiveRideCubit, DriverActiveRideState>(
        listenWhen: (prev, curr) =>
            curr.status == DriverActiveRideStatus.cancelled,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride was cancelled')),
          );
          context.go(RouteNames.driverHome);
        },
        builder: (context, state) {
          if (state.status == DriverActiveRideStatus.loading ||
              state.status == DriverActiveRideStatus.transitioning) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == DriverActiveRideStatus.noActiveRide) {
            return const Center(child: Text('No active ride'));
          }
          if (state.status == DriverActiveRideStatus.failure) {
            return Center(child: Text(state.errorMessage));
          }
          final ride = state.ride;
          if (ride == null) return const SizedBox.shrink();
          return _RideDetails(ride: ride, driverPosition: _driverPosition);
        },
      ),
    );
  }
}

class _RideDetails extends StatelessWidget {
  const _RideDetails({required this.ride, required this.driverPosition});

  final ActiveDriverRideResponse ride;
  final Position? driverPosition;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DriverActiveRideCubit>();
    final pickupPoint = LatLng(ride.pickup.lat, ride.pickup.lng);
    final dropoffPoint = LatLng(ride.dropoff.lat, ride.dropoff.lng);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 250.h,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: pickupPoint,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'khfif_drif',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pickupPoint,
                      child: const Icon(Icons.trip_origin,
                          color: Colors.green, size: 32),
                    ),
                    Marker(
                      point: dropoffPoint,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 32),
                    ),
                    if (driverPosition != null)
                      Marker(
                        point: LatLng(
                          driverPosition!.latitude,
                          driverPosition!.longitude,
                        ),
                        child: const Icon(Icons.directions_car,
                            color: Colors.blue, size: 32),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Passenger: ${ride.passengerFullName}'),
                Text('Phone: ${ride.passengerPhone}'),
                const SizedBox(height: 8),
                Text('Pickup: ${ride.pickup.address}'),
                Text('Dropoff: ${ride.dropoff.address}'),
                Text('Fare: ${ride.finalFare} DZD'),
                const SizedBox(height: 16),
                if (ride.state == ActiveDriverRideState.accepted)
                  ElevatedButton(
                    onPressed: cubit.markArrived,
                    child: const Text('Mark Arrived'),
                  ),
                if (ride.state == ActiveDriverRideState.arrived)
                  ElevatedButton(
                    onPressed: cubit.startRide,
                    child: const Text('Start Ride'),
                  ),
                if (ride.state == ActiveDriverRideState.inProgress)
                  ElevatedButton(
                    onPressed: cubit.completeRide,
                    child: const Text('Complete Ride'),
                  ),
                const SizedBox(height: 8),
                if (ride.state == ActiveDriverRideState.accepted ||
                    ride.state == ActiveDriverRideState.arrived)
                  OutlinedButton(
                    onPressed: () =>
                        cubit.cancelRide(CancelReason.driverVehicleIssue),
                    child: const Text('Cancel Ride'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
