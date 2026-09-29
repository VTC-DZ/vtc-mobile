import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/passenger_ride_models.dart';
import '../../../../../shared/utils/fare_formatter.dart';
import '../../../../../shared/widgets/expiry_indicators.dart';
import 'offer_parts.dart';

/// A driver's bid: identity, vehicle, ETA, price vs. the passenger's own
/// offer, a live countdown, and Decline / Accept. Tapping the upper part
/// opens the full details ([onTap]).
class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.isAccepting,
    this.isAcceptingThis = false,
    this.proposedFare,
    required this.onTap,
    required this.onAccept,
    required this.onRefuse,
    required this.onExpired,
  });

  final OfferEntry offer;

  /// Any offer is being accepted — the actions are disabled.
  final bool isAccepting;

  /// This offer is the one being accepted — its Accept shows a spinner.
  final bool isAcceptingThis;

  /// The fare the passenger originally proposed. When provided, the card shows
  /// how each offer compares (cheaper / costlier / matching).
  final int? proposedFare;

  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  final VoidCallback onExpired;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderDefault(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black
                .withValues(alpha: AppColors.isDark(context) ? 0.30 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drains over the offer window; removes the card when it runs out.
          ExpiryProgressBar(
            key: ValueKey(offer.expiresAt),
            expiresAt: offer.expiresAt,
            barHeight: 3,
            onExpired: onExpired,
          ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 10.h),
                child: _Summary(offer: offer, proposedFare: proposedFare),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: OfferActions(
              fare: offer.fare,
              isAccepting: isAccepting,
              isAcceptingThis: isAcceptingThis,
              onAccept: onAccept,
              onDecline: onRefuse,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar + name/rating/vehicle on the left, price + delta on the right, and a
/// meta row (plate · ETA · countdown) underneath.
class _Summary extends StatelessWidget {
  const _Summary({required this.offer, required this.proposedFare});

  final OfferEntry offer;
  final int? proposedFare;

  @override
  Widget build(BuildContext context) {
    final eta = etaMinutes(offer.etaSeconds);
    final secondary = AppColors.textSecondary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DriverAvatar(name: offer.driverFullName),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          offer.driverFullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text(context),
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18.w, color: secondary),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      DriverRating(ratingAvg: offer.driverRatingAvg),
                      SizedBox(width: 6.w),
                      Text('·',
                          style: AppTextStyles.labelSmall(context)
                              .copyWith(color: secondary)),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          offer.vehicleModel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium(context)
                              .copyWith(color: secondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatFare(offer.fare)} DZD',
                  style: AppTextStyles.headingSmall(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (proposedFare != null) ...[
                  SizedBox(height: 4.h),
                  OfferFareDelta(fare: offer.fare, proposedFare: proposedFare!),
                ],
              ],
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            if (offer.vehiclePlate != null) ...[
              VehiclePlateChip(plate: offer.vehiclePlate!),
              SizedBox(width: 10.w),
            ],
            if (eta != null) ...[
              Icon(Icons.schedule_rounded, size: 14.w, color: secondary),
              SizedBox(width: 3.w),
              Flexible(
                child: Text(
                  '$eta min away',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: AppTextStyles.labelMedium(context)
                      .copyWith(color: secondary),
                ),
              ),
            ],
            const Spacer(),
            ExpiryCountdown(
              key: ValueKey(offer.expiresAt),
              expiresAt: offer.expiresAt,
            ),
          ],
        ),
      ],
    );
  }
}
