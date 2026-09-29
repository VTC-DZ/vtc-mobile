import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/utils/fare_formatter.dart';

export '../../../../../shared/widgets/ride_identity.dart';

/// Amber for "costlier than your offer" — a nudge, not an error. No app-wide
/// warning token exists (same value as the expiry urgency ladder).
const Color offerCostlierAmber = Color(0xFFF59E0B);

/// Server ETA in seconds → whole minutes, rounded up (`null` stays `null`).
int? etaMinutes(int? etaSeconds) =>
    etaSeconds == null ? null : (etaSeconds / 60).ceil();

/// `★ 4.8`, or a "New driver" pill when the driver has no ratings yet.
class DriverRating extends StatelessWidget {
  const DriverRating({super.key, required this.ratingAvg});

  final double? ratingAvg;

  static const Color _star = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final rating = ratingAvg;
    if (rating == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          'New driver',
          style: AppTextStyles.labelSmall(context).copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 15.w, color: _star),
        SizedBox(width: 2.w),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.labelMedium(context).copyWith(
            color: AppColors.text(context),
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// How an offer compares to the passenger's own price: "Your price",
/// "−100 DZD" (cheaper, green) or "+150 DZD" (costlier, amber).
class OfferFareDelta extends StatelessWidget {
  const OfferFareDelta({
    super.key,
    required this.fare,
    required this.proposedFare,
  });

  final int fare;
  final int proposedFare;

  @override
  Widget build(BuildContext context) {
    final diff = fare - proposedFare;
    final (color, icon, label) = switch (diff) {
      0 => (
          AppColors.textSecondary(context),
          Icons.check_rounded,
          'Your price',
        ),
      > 0 => (
          offerCostlierAmber,
          Icons.north_rounded,
          '+${formatFare(diff)} DZD',
        ),
      _ => (
          AppColors.primary,
          Icons.south_rounded,
          '−${formatFare(-diff)} DZD',
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.w, color: color),
          SizedBox(width: 2.w),
          Text(
            label,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Decline (outlined) + "Accept · 1 350 DZD" (filled, twice as wide). Both
/// disable while any accept is in flight; the offer being accepted shows a
/// spinner on its Accept button.
class OfferActions extends StatelessWidget {
  const OfferActions({
    super.key,
    required this.fare,
    required this.isAccepting,
    required this.isAcceptingThis,
    required this.onAccept,
    required this.onDecline,
    this.height = 44,
  });

  final int fare;

  /// Any offer is being accepted — disables both buttons.
  final bool isAccepting;

  /// This offer is the one being accepted — shows the spinner.
  final bool isAcceptingThis;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// Button height in design pixels (scaled with `.h`).
  final double height;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.r),
    );
    final minimumSize = Size(0, height.h);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text(context),
              side: BorderSide(color: AppColors.borderDefault(context)),
              minimumSize: minimumSize,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              shape: shape,
            ),
            onPressed: isAccepting ? null : onDecline,
            child: Text(
              'Decline',
              style: AppTextStyles.labelLarge(context).copyWith(
                color: isAccepting
                    ? AppColors.buttonDisabledText(context)
                    : AppColors.textSecondary(context),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              elevation: 0,
              minimumSize: minimumSize,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              shape: shape,
            ),
            onPressed: isAccepting ? null : onAccept,
            child: isAcceptingThis
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Accept · ${formatFare(fare)} DZD',
                      style: AppTextStyles.labelLarge(context).copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
