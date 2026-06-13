import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

class FemaleOnlyWidget extends StatelessWidget {
  const FemaleOnlyWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderDefault(context),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.female_rounded,
            size: 20.w,
            color: value
                ? AppColors.primary
                : AppColors.textSecondary(context),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Female Driver Only',
                  style: AppTextStyles.labelMedium(context),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Request a female driver for this trip',
                  style: AppTextStyles.bodySmall(context),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
