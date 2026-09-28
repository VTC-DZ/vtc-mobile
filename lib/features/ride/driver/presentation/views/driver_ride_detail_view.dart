import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/widgets/app_slim_app_bar.dart';
import '../../../shared/models/shared_ride_models.dart';
import '../../../shared/widgets/ride_detail/ride_cancellation_reason.dart';
import '../../../shared/widgets/ride_detail/ride_detail_addresses_card.dart';
import '../../../shared/widgets/ride_detail/ride_detail_message.dart';
import '../../../shared/widgets/ride_detail/ride_detail_status_header.dart';
import '../../../shared/widgets/ride_detail/ride_timeline_card.dart';
import '../../../shared/widgets/ride_detail/ride_trip_facts_card.dart';
import '../cubit/driver_ride_detail_cubit/driver_ride_detail_cubit.dart';
import '../cubit/driver_ride_detail_cubit/driver_ride_detail_state.dart';
import 'widgets/active/fare_card.dart';
import 'widgets/active/passenger_info_card.dart';

/// Full detail for a single past ride, reached by tapping a history card.
class DriverRideDetailView extends StatelessWidget {
  const DriverRideDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppSlimAppBar(
        title: 'Ride Details',
        onLeadingTap: () => context.pop(),
      ),
      body: SafeArea(
        child: BlocBuilder<DriverRideDetailCubit, DriverRideDetailState>(
          builder: (context, state) {
            if (state.status == DriverRideDetailStatus.initial ||
                state.status == DriverRideDetailStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final ride = state.ride;
            if (state.status == DriverRideDetailStatus.failure ||
                ride == null) {
              return RideDetailMessage(
                icon: Icons.error_outline_rounded,
                text: state.errorMessage.isEmpty
                    ? 'Failed to load ride details.'
                    : state.errorMessage,
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RideDetailStatusHeader(
                    serviceType: ride.serviceType,
                    state: ride.state,
                    date: ride.displayDate,
                  ),
                  SizedBox(height: 12.h),
                  PassengerInfoCard(
                    fullName: ride.passengerFullName.isEmpty
                        ? 'Passenger'
                        : ride.passengerFullName,
                    phone:
                        ride.passengerPhone.isEmpty ? '—' : ride.passengerPhone,
                  ),
                  SizedBox(height: 12.h),
                  RideDetailAddressesCard(
                    pickup: ride.pickupAddress,
                    dropoff: ride.dropoffAddress,
                  ),
                  SizedBox(height: 12.h),
                  FareCard(finalFare: ride.finalFare),
                  if (ride.distanceMeters != null ||
                      ride.durationSeconds != null) ...[
                    SizedBox(height: 12.h),
                    RideTripFactsCard(
                      distanceMeters: ride.distanceMeters,
                      durationSeconds: ride.durationSeconds,
                    ),
                  ],
                  SizedBox(height: 12.h),
                  RideTimelineCard(
                    acceptedAt: ride.acceptedAt,
                    arrivedAt: ride.arrivedAt,
                    startedAt: ride.startedAt,
                    completedAt: ride.completedAt,
                    cancelledAt: ride.cancelledAt,
                  ),
                  if (ride.state == RideOutcome.cancelled &&
                      (ride.cancellationReason?.isNotEmpty ?? false)) ...[
                    SizedBox(height: 12.h),
                    RideCancellationReason(reason: ride.cancellationReason!),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
