import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/available_rides_cubit/available_rides_cubit.dart';
import '../cubit/available_rides_cubit/available_rides_state.dart';

class AvailableRidesView extends StatefulWidget {
  const AvailableRidesView({super.key});

  @override
  State<AvailableRidesView> createState() => _AvailableRidesViewState();
}

class _AvailableRidesViewState extends State<AvailableRidesView> {
  @override
  void initState() {
    super.initState();
    context.read<AvailableRidesCubit>().loadAvailableRides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Rides')),
      body: BlocBuilder<AvailableRidesCubit, AvailableRidesState>(
        builder: (context, state) {
          if (state.status == AvailableRidesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AvailableRidesStatus.failure) {
            return Center(child: Text(state.errorMessage));
          }
          if (state.rides.isEmpty) {
            return const Center(child: Text('No rides available'));
          }
          return ListView.builder(
            itemCount: state.rides.length,
            itemBuilder: (context, index) {
              final ride = state.rides[index];
              return ListTile(
                title: Text(ride.pickup.address),
                subtitle: Text(ride.dropoff.address),
                trailing: Text('${ride.proposedFare} DZD'),
                onTap: () => _showBidDialog(context, ride.rideRequestId),
              );
            },
          );
        },
      ),
    );
  }

  void _showBidDialog(BuildContext context, String rideRequestId) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Bid'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Your fare (DZD)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final fare = int.tryParse(controller.text);
              if (fare != null) {
                context
                    .read<AvailableRidesCubit>()
                    .submitBid(rideRequestId, fare);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Bid'),
          ),
        ],
      ),
    );
  }
}
