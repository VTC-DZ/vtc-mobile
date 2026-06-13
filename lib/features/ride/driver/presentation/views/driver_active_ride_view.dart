import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/driver_ride_models.dart';
import '../cubit/driver_active_ride_cubit/driver_active_ride_cubit.dart';
import '../cubit/driver_active_ride_cubit/driver_active_ride_state.dart';

class DriverActiveRideView extends StatefulWidget {
  const DriverActiveRideView({super.key});

  @override
  State<DriverActiveRideView> createState() => _DriverActiveRideViewState();
}

class _DriverActiveRideViewState extends State<DriverActiveRideView> {
  @override
  void initState() {
    super.initState();
    context.read<DriverActiveRideCubit>().loadActiveRide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Ride')),
      body: BlocBuilder<DriverActiveRideCubit, DriverActiveRideState>(
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
          return _RideDetails(ride: ride);
        },
      ),
    );
  }
}

class _RideDetails extends StatelessWidget {
  const _RideDetails({required this.ride});

  final ActiveDriverRideResponse ride;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DriverActiveRideCubit>();
    return Padding(
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
          const Spacer(),
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
              onPressed: () => cubit.cancelRide(CancelReason.driverVehicleIssue),
              child: const Text('Cancel Ride'),
            ),
        ],
      ),
    );
  }
}
