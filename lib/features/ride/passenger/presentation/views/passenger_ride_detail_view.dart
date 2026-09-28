import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_slim_app_bar.dart';
import '../../../shared/widgets/ride_detail/ride_cancellation_reason.dart';
import '../../../shared/widgets/ride_detail/ride_detail_addresses_card.dart';
import '../../../shared/widgets/ride_detail/ride_detail_message.dart';
import '../../../shared/widgets/ride_detail/ride_detail_route_map.dart';
import '../../../shared/widgets/ride_detail/ride_detail_status_header.dart';
import '../../../shared/widgets/ride_detail/ride_timeline_card.dart';
import '../../../shared/widgets/ride_detail/ride_trip_facts_card.dart';
import '../../data/models/passenger_ride_models.dart';
import '../cubit/passenger_ride_detail_cubit/passenger_ride_detail_cubit.dart';
import '../cubit/passenger_ride_detail_cubit/passenger_ride_detail_state.dart';
import 'widgets/active_ride/driver_card.dart';
import 'widgets/active_ride/fare_card.dart';

/// Full detail for a single past ride, reached by tapping a history card.
///
/// The tapped history entry renders at once; the route map, trip facts and
/// timeline fill in when `GET /rides/{rideRequestId}` answers. A failed load
/// only replaces those sections, never the whole page.
class PassengerRideDetailView extends StatelessWidget {
  const PassengerRideDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppSlimAppBar(
        title: 'Ride Details',
        onLeadingTap: () => context.pop(),
      ),
      body: SafeArea(
        child: BlocBuilder<PassengerRideDetailCubit, PassengerRideDetailState>(
          builder: (context, state) {
            final summary = state.summary;
            final detail = state.detail;
            // The detail is fresher; the history entry fills in until then.
            final rideState = detail?.state ?? summary.state;
            final finalFare = detail?.finalFare ?? summary.finalFare;
            final route = detail?.routePoints;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (route != null) ...[
                    RideDetailRouteMap(points: route),
                    SizedBox(height: 12.h),
                  ],
                  RideDetailStatusHeader(
                    serviceType: summary.serviceType,
                    state: rideState,
                    date: summary.displayDate,
                  ),
                  SizedBox(height: 12.h),
                  DriverCard(
                    driver: detail?.driver ??
                        DriverInRide(
                          id: '',
                          fullName: summary.driverFullName.isEmpty
                              ? 'Driver'
                              : summary.driverFullName,
                          phone: '',
                          vehicleModel: summary.vehicleModel,
                          vehiclePlate: summary.vehiclePlate,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  RideDetailAddressesCard(
                    pickup: summary.pickupAddress,
                    dropoff: summary.dropoffAddress,
                  ),
                  SizedBox(height: 12.h),
                  FareCard(finalFare: finalFare),
                  SizedBox(height: 12.h),
                  ..._detailSections(context, state),
                  if (rideState == RideOutcome.cancelled &&
                      (summary.cancellationReason?.isNotEmpty ?? false)) ...[
                    SizedBox(height: 12.h),
                    RideCancellationReason(reason: summary.cancellationReason!),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// The sections only the detail endpoint can fill: trip facts + timeline,
  /// or a loader / inline error in their place.
  List<Widget> _detailSections(
    BuildContext context,
    PassengerRideDetailState state,
  ) {
    final detail = state.detail;
    switch (state.status) {
      case PassengerRideDetailStatus.initial:
      case PassengerRideDetailStatus.loading:
        return [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ];
      case PassengerRideDetailStatus.notFound:
        return [
          const _DetailUnavailable(message: 'Ride not found.'),
        ];
      case PassengerRideDetailStatus.failure:
        return [
          _DetailUnavailable(
            message: state.errorMessage.isEmpty
                ? "Couldn't load ride details."
                : state.errorMessage,
            onRetry: () => context.read<PassengerRideDetailCubit>().load(),
          ),
        ];
      case PassengerRideDetailStatus.loaded:
        if (detail == null) return const [];
        return [
          if (detail.distanceMeters != null ||
              detail.durationSeconds != null) ...[
            RideTripFactsCard(
              distanceMeters: detail.distanceMeters,
              durationSeconds: detail.durationSeconds,
            ),
            SizedBox(height: 12.h),
          ],
          RideTimelineCard(
            acceptedAt: detail.acceptedAt,
            arrivedAt: detail.arrivedAt,
            startedAt: detail.startedAt,
            completedAt: detail.completedAt,
            cancelledAt: detail.cancelledAt,
          ),
        ];
    }
  }
}

/// Stands in for the detail-only sections when they couldn't be loaded.
class _DetailUnavailable extends StatelessWidget {
  const _DetailUnavailable({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 6.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault(context), width: 1.w),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20.w,
            color: AppColors.textSecondary(context),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Shown when the route was opened without a history entry (e.g. the app was
/// restored onto this screen and go_router dropped the `extra`).
class PassengerRideDetailMissing extends StatelessWidget {
  const PassengerRideDetailMissing({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppSlimAppBar(
        title: 'Ride Details',
        onLeadingTap: () => context.pop(),
      ),
      body: const SafeArea(
        child: RideDetailMessage(
          icon: Icons.error_outline_rounded,
          text: 'This ride is no longer available. Open it again from your '
              'ride history.',
        ),
      ),
    );
  }
}
