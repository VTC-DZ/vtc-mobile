import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

class PassengerInfoCard extends StatelessWidget {
  const PassengerInfoCard({
    super.key,
    required this.fullName,
    required this.phone,
  });

  final String fullName;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person_rounded,
                color: AppColors.primary, size: 28.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Passenger',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  fullName,
                  style: AppTextStyles.bodyLarge(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2.h),
                Text(
                  phone,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          // Phone icon — requires url_launcher to be active; shown as UI stub
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.phone_rounded,
                color: AppColors.primary, size: 20.w),
          ),
        ],
      ),
    );
  }
}
