import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../cubit/available_rides_cubit/available_rides_cubit.dart';
import '../../cubit/available_rides_cubit/available_rides_state.dart';
import 'available_ride_card.dart';
import 'bid_sheet.dart';

/// Floating overlay that shows incoming ride broadcast cards on top of any
/// driver screen. Anchored to the bottom of the screen. Reuses [AvailableRideCard]
/// so the timer bar, colors, and bid sheet are identical to the list view.
class BroadcastOverlay extends StatelessWidget {
  const BroadcastOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AvailableRidesCubit, AvailableRidesState>(
      buildWhen: (prev, curr) => prev.rides != curr.rides,
      builder: (context, state) {
        if (state.rides.isEmpty) return const SizedBox.shrink();

        final cubit = context.read<AvailableRidesCubit>();

        return Positioned(
          left: 16.w,
          right: 16.w,
          bottom: MediaQuery.of(context).padding.bottom + 16.h,
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.6,
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final ride in state.rides)
                      AvailableRideCard(
                        key: ValueKey(ride.rideRequestId),
                        ride: ride,
                        compact: true,
                        onBid: () async {
                          final fare = await showBidSheet(
                            context,
                            proposedFare: ride.proposedFare,
                          );
                          if (fare != null) {
                            cubit.submitBid(ride.rideRequestId, fare);
                          }
                        },
                        onIgnore: () => cubit.ignoreRide(ride.rideRequestId),
                        onExpired: () => cubit.ignoreRide(ride.rideRequestId),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
