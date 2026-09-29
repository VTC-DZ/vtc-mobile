import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../models/shared_ride_models.dart';
import '../../utils/date_formatter.dart';
import '../../utils/fare_formatter.dart';
import '../service_type_chip.dart';

/// Opening block of a ride-detail screen, sitting on the page background:
/// outcome + service chips, the fare in large type, and the ride's most
/// relevant date and time.
class RideDetailSummary extends StatelessWidget {
  const RideDetailSummary({
    super.key,
    required this.serviceType,
    required this.state,
    required this.fare,
    this.date,
  });

  final ServiceType serviceType;
  final RideOutcome state;

  /// Final (agreed) fare in whole DZD.
  final int fare;

  /// ISO-8601 timestamp shown under the fare; hidden when `null`.
  final String? date;

  @override
  Widget build(BuildContext context) {
    final completed = state == RideOutcome.completed;
    final formattedDate = date == null ? '' : formatRideDateTime(date!);
    // A cancelled ride was never paid — mute its fare.
    final fareColor = state == RideOutcome.cancelled
        ? AppColors.textSecondary(context)
        : AppColors.text(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RideStateBadge(state: state),
            ServiceTypeChip(serviceType: serviceType),
          ],
        ),
        SizedBox(height: 14.h),
        Text(
          completed ? 'Trip fare' : 'Agreed fare',
          style: AppTextStyles.labelMedium(context).copyWith(
            color: AppColors.textSecondary(context),
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  formatFare(fare),
                  style: AppTextStyles.displayLarge(context).copyWith(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w800,
                    color: fareColor,
                    height: 1.1,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              'DZD',
              style: AppTextStyles.labelLarge(context).copyWith(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (formattedDate.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13.w,
                color: AppColors.textSecondary(context),
              ),
              SizedBox(width: 6.w),
              Text(
                formattedDate,
                style: AppTextStyles.labelMedium(context).copyWith(
                  color: AppColors.textSecondary(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Tinted pill with the ride outcome's icon and label.
class RideStateBadge extends StatelessWidget {
  const RideStateBadge({super.key, required this.state});

  final RideOutcome state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: state.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(state.icon, size: 14.w, color: state.color),
          SizedBox(width: 3.w),
          Text(
            state.label,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: state.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
