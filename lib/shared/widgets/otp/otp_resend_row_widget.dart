import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/countdown_format.dart';

/// Resend countdown + button row, shared by every OTP screen.
class OtpResendRowWidget extends StatelessWidget {
  const OtpResendRowWidget({
    super.key,
    required this.secondsRemaining,
    required this.resendCount,
    required this.onResend,
  });

  /// Seconds until the code can be resent; `0` shows the resend link.
  final int secondsRemaining;

  /// Resends used so far.
  final int resendCount;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final bool waiting = secondsRemaining > 0;
    final bool exhausted = resendCount >= AppConstants.otpMaxResendCount;

    return Column(
      children: [
        if (waiting)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined,
                  size: 15.sp, color: AppColors.textSecondary(context)),
              SizedBox(width: 6.w),
              Text(
                AppStrings.otpResendIn(formatMmSs(secondsRemaining)),
                style: AppTextStyles.bodySmall(context),
              ),
            ],
          ),
        if (!waiting && !exhausted)
          GestureDetector(
            onTap: onResend,
            child: Text(
              AppStrings.otpResend,
              style: AppTextStyles.labelMedium(context).copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        if (!waiting && exhausted)
          Text(
            AppStrings.otpResendExhausted,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.error,
            ),
          ),
        if (resendCount > 0 && !exhausted)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              AppStrings.otpResendsRemaining(
                  AppConstants.otpMaxResendCount - resendCount),
              style: AppTextStyles.labelSmall(context),
            ),
          ),
      ],
    );
  }
}
