import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/cancel_ride_dialog.dart';
import '../../../../../shared/widgets/app_slim_app_bar.dart';
import '../../data/models/passenger_ride_models.dart';
import '../cubit/waiting_offers_cubit/waiting_offers_cubit.dart';
import '../cubit/waiting_offers_cubit/waiting_offers_state.dart';
import 'widgets/waiting_offers/empty_offers_placeholder.dart';
import 'widgets/waiting_offers/offer_card.dart';
import 'widgets/waiting_offers/phase_badge.dart';
import 'widgets/waiting_offers/ride_summary_card.dart';

class WaitingOffersView extends StatelessWidget {
  const WaitingOffersView({super.key, required this.args});

  final WaitingOffersArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WaitingOffersCubit, WaitingOffersState>(
      listenWhen: (prev, curr) =>
          prev.acceptStatus != curr.acceptStatus ||
          prev.cancelStatus != curr.cancelStatus ||
          prev.refuseStatus != curr.refuseStatus,
      listener: (context, state) {
        if (state.acceptStatus == AcceptStatus.success) {
          _showAcceptedSheet(context, state);
        }
        if (state.cancelStatus == CancelStatus.success) {
          context.go(RouteNames.passengerHome);
        }
        if (state.acceptStatus == AcceptStatus.failure ||
            state.cancelStatus == CancelStatus.failure ||
            state.refuseStatus == RefuseStatus.failure) {
          if (state.errorMessage.isNotEmpty) {
            AppToast.error(state.errorMessage);
          }
        }
      },
      builder: (context, state) {
        final isAccepted = state.acceptStatus == AcceptStatus.success;
        final isAccepting = state.acceptStatus == AcceptStatus.loading;
        final isCancelling = state.cancelStatus == CancelStatus.loading;

        return Scaffold(
          backgroundColor: AppColors.background(context),
          appBar: AppSlimAppBar(
            title: state.rideRequestPhase == RideRequestPhase.negotiating
                ? 'Review Offers'
                : 'Waiting for Drivers',
            onLeadingTap:
                isAccepted ? null : () => context.go(RouteNames.passengerHome),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RideSummaryCard(args: args),
                      SizedBox(height: 20.h),
                      PhaseBadge(
                        phase: state.rideRequestPhase,
                        broadcastCount: args.response.broadcastDriverCount,
                        offerCount: state.offers.length,
                      ),
                      SizedBox(height: 20.h),
                      if (state.offers.isEmpty &&
                          state.rideRequestPhase == RideRequestPhase.requested) ...[
                        const EmptyOffersPlaceholder(),
                      ] else ...[
                        Text(
                          'Driver Offers',
                          style: AppTextStyles.headingSmall(context).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ...state.offers.map(
                          (offer) => OfferCard(
                            offer: offer,
                            isAccepting: isAccepting,
                            onAccept: () => context
                                .read<WaitingOffersCubit>()
                                .acceptOffer(offer.offerId),
                            onRefuse: () => context
                                .read<WaitingOffersCubit>()
                                .refuseOffer(offer.offerId),
                          ),
                        ),
                      ],
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              if (!isAccepted)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    8.h,
                    20.w,
                    MediaQuery.of(context).padding.bottom + 16.h,
                  ),
                  child: TextButton(
                    onPressed: (isAccepting || isCancelling)
                        ? null
                        : () async {
                            final reason =
                                await showCancelRideDialog(context);
                            if (reason != null && context.mounted) {
                              context
                                  .read<WaitingOffersCubit>()
                                  .cancelRide(reason);
                            }
                          },
                    child: isCancelling
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.error,
                            ),
                          )
                        : Text(
                            'Cancel Ride Request',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAcceptedSheet(BuildContext context, WaitingOffersState state) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.background(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24.w,
          24.h,
          24.w,
          MediaQuery.of(context).padding.bottom + 24.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 56.w),
            SizedBox(height: 16.h),
            Text(
              'Ride Accepted!',
              style: AppTextStyles.headingSmall(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your driver is on the way.',
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(RouteNames.passengerHome);
                },
                child: Text(
                  'Back to Home',
                  style: AppTextStyles.labelLarge(context).copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
