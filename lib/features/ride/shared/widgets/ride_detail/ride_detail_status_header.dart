import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../models/shared_ride_models.dart';
import '../../utils/date_formatter.dart';
import '../service_type_chip.dart';

/// Top card of a ride-detail screen: service type + outcome badge, and the
/// ride's most relevant date.
class RideDetailStatusHeader extends StatelessWidget {
  const RideDetailStatusHeader({
    super.key,
    required this.serviceType,
    required this.state,
    this.date,
  });

  final ServiceType serviceType;
  final RideOutcome state;

  /// ISO-8601 timestamp shown on the right; hidden when `null`.
  final String? date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault(context), width: 1.w),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ServiceTypeChip(serviceType: serviceType),
                RideStateBadge(state: state),
              ],
            ),
          ),
          if (date != null) ...[
            SizedBox(width: 6.w),
            Text(
              formatRideDate(date!),
              style: AppTextStyles.labelSmall(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ],
      ),
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
