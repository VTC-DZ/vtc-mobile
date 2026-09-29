import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Low-emphasis red "Cancel ride" link at the bottom of the active-ride
/// sheet. [onPressed] owns any confirmation step.
class ActiveRideCancelButton extends StatelessWidget {
  const ActiveRideCancelButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        ),
        icon: Icon(Icons.close_rounded, size: 18.w),
        label: Text(
          'Cancel ride',
          style: AppTextStyles.labelLarge(context).copyWith(
            color: enabled
                ? AppColors.error
                : AppColors.buttonDisabledText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
