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
import '../../../shared/widgets/ride_detail/ride_detail_person_card.dart';
import '../../../shared/widgets/ride_detail/ride_detail_scaffold.dart';
import '../../../shared/widgets/ride_detail/ride_detail_skeleton.dart';
import '../../../shared/widgets/ride_detail/ride_detail_summary.dart';
import '../../../shared/widgets/ride_detail/ride_timeline_card.dart';
import '../../../shared/widgets/ride_detail/ride_trip_facts_card.dart';
import '../../data/models/passenger_ride_models.dart';
import '../cubit/passenger_ride_detail_cubit/passenger_ride_detail_cubit.dart';
import '../cubit/passenger_ride_detail_cubit/passenger_ride_detail_state.dart';

/// Full detail for a single past ride, reached by tapping a history card.
///
/// The tapped history entry renders at once; the route map, trip facts,
/// driver contact and timeline fill in when `GET /rides/{rideRequestId}`
/// answers. A failed load only replaces those sections, never the whole page.
class PassengerRideDetailView extends StatelessWidget {
  const PassengerRideDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PassengerRideDetailCubit, PassengerRideDetailState>(
      builder: (context, state) {
        final summary = state.summary;
        final detail = state.detail;
        // The detail is fresher; the history entry fills in until then.
        final rideState = detail?.state ?? summary.state;
        final driver = detail?.driver;

        return RideDetailScaffold(
          onBack: () => context.pop(),
          routePoints: detail?.routePoints,
          state: rideState,
          children: [
            RideDetailSummary(
              serviceType: summary.serviceType,
              state: rideState,
              fare: detail?.finalFare ?? summary.finalFare,
              date: detail?.completedAt ??
                  detail?.cancelledAt ??
                  summary.displayDate,
            ),
            ..._detailSections(context, state),
            RideDetailAddressesCard(
              pickup: summary.pickupAddress,
              dropoff: summary.dropoffAddress,
              pickupTime: detail?.startedAt,
              dropoffTime: detail?.completedAt,
            ),
            RideDetailPersonCard(
              role: 'Your driver',
              name: _orFallback(
                driver?.fullName ?? summary.driverFullName,
                'Driver',
              ),
              phone: driver?.phone,
              vehicleModel: driver?.vehicleModel ?? summary.vehicleModel,
              vehiclePlate: driver?.vehiclePlate ?? summary.vehiclePlate,
            ),
            if (detail != null)
              RideTimelineCard(
                acceptedAt: detail.acceptedAt,
                arrivedAt: detail.arrivedAt,
                startedAt: detail.startedAt,
                completedAt: detail.completedAt,
                cancelledAt: detail.cancelledAt,
              ),
            if (rideState == RideOutcome.cancelled &&
                (summary.cancellationReason?.isNotEmpty ?? false))
              RideCancellationReason(reason: summary.cancellationReason!),
          ],
        );
      },
    );
  }

  static String _orFallback(String value, String fallback) =>
      value.trim().isEmpty ? fallback : value;

  /// What only the detail endpoint can fill in near the top: trip facts, or
  /// a skeleton / inline error in their place. (The timeline follows once
  /// loaded.)
  List<Widget> _detailSections(
    BuildContext context,
    PassengerRideDetailState state,
  ) {
    final detail = state.detail;
    switch (state.status) {
      case PassengerRideDetailStatus.initial:
      case PassengerRideDetailStatus.loading:
        return const [RideDetailSkeleton()];
      case PassengerRideDetailStatus.notFound:
        return const [_DetailUnavailable(message: 'Ride not found.')];
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
        if (detail == null ||
            (detail.distanceMeters == null && detail.durationSeconds == null)) {
          return const [];
        }
        return [
          RideTripFactsCard(
            distanceMeters: detail.distanceMeters,
            durationSeconds: detail.durationSeconds,
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
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault(context)),
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
