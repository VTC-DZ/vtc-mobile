import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'ride_detail_section.dart';

/// Red-tinted card explaining why a ride was cancelled.
class RideCancellationReason extends StatelessWidget {
  const RideCancellationReason({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return RideDetailSection(
      color: AppColors.error.withValues(alpha: 0.07),
      borderColor: AppColors.error.withValues(alpha: 0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 20.w,
              color: AppColors.error,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancellation reason',
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  reason,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.text(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
