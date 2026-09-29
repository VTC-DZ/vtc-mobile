import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/shared_ride_models.dart';
import '../../../shared/widgets/ride_detail/ride_cancellation_reason.dart';
import '../../../shared/widgets/ride_detail/ride_detail_addresses_card.dart';
import '../../../shared/widgets/ride_detail/ride_detail_message.dart';
import '../../../shared/widgets/ride_detail/ride_detail_person_card.dart';
import '../../../shared/widgets/ride_detail/ride_detail_scaffold.dart';
import '../../../shared/widgets/ride_detail/ride_detail_skeleton.dart';
import '../../../shared/widgets/ride_detail/ride_detail_summary.dart';
import '../../../shared/widgets/ride_detail/ride_timeline_card.dart';
import '../../../shared/widgets/ride_detail/ride_trip_facts_card.dart';
import '../cubit/driver_ride_detail_cubit/driver_ride_detail_cubit.dart';
import '../cubit/driver_ride_detail_cubit/driver_ride_detail_state.dart';

/// Full detail for a single past ride, reached by tapping a history card.
class DriverRideDetailView extends StatelessWidget {
  const DriverRideDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverRideDetailCubit, DriverRideDetailState>(
      builder: (context, state) {
        final ride = state.ride;
        return RideDetailScaffold(
          onBack: () => context.pop(),
          routePoints: state.routePoints,
          state: ride?.state,
          children: switch ((state.status, ride)) {
            (DriverRideDetailStatus.failure, _) ||
            (DriverRideDetailStatus.loaded, null) =>
              [_LoadFailure(message: state.errorMessage)],
            (DriverRideDetailStatus.loaded, final ride?) => [
                RideDetailSummary(
                  serviceType: ride.serviceType,
                  state: ride.state,
                  fare: ride.finalFare,
                  date: ride.displayDate,
                ),
                if (ride.distanceMeters != null ||
                    ride.durationSeconds != null)
                  RideTripFactsCard(
                    distanceMeters: ride.distanceMeters,
                    durationSeconds: ride.durationSeconds,
                  ),
                RideDetailAddressesCard(
                  pickup: ride.pickupAddress,
                  dropoff: ride.dropoffAddress,
                  pickupTime: ride.startedAt,
                  dropoffTime: ride.completedAt,
                ),
                RideDetailPersonCard(
                  role: 'Your passenger',
                  name: ride.passengerFullName.isEmpty
                      ? 'Passenger'
                      : ride.passengerFullName,
                  phone: ride.passengerPhone,
                ),
                RideTimelineCard(
                  acceptedAt: ride.acceptedAt,
                  arrivedAt: ride.arrivedAt,
                  startedAt: ride.startedAt,
                  completedAt: ride.completedAt,
                  cancelledAt: ride.cancelledAt,
                ),
                if (ride.state == RideOutcome.cancelled &&
                    (ride.cancellationReason?.isNotEmpty ?? false))
                  RideCancellationReason(reason: ride.cancellationReason!),
              ],
            _ => const [RideDetailSkeleton(includeSummary: true)],
          },
        );
      },
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Column(
        children: [
          RideDetailMessage(
            icon: Icons.error_outline_rounded,
            text: message.isEmpty ? 'Failed to load ride details.' : message,
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: () => context.read<DriverRideDetailCubit>().load(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
