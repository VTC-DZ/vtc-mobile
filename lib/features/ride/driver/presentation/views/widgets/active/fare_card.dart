import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Displays the agreed fare for the active ride.
class FareCard extends StatelessWidget {
  const FareCard({super.key, required this.finalFare});

  final int finalFare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.payments_rounded,
                color: AppColors.primary, size: 20.w),
          ),
          SizedBox(width: 12.w),
          Text(
            'Agreed Fare',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          const Spacer(),
          Text(
            '$finalFare DZD',
            style: AppTextStyles.headingSmall(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
