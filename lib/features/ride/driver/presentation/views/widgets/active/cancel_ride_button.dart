import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Outlined cancel button for the active ride. Calls [onCancel] when pressed —
/// the parent wires this to `DriverActiveRideCubit.cancelRide`.
class CancelRideButton extends StatelessWidget {
  const CancelRideButton({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          'Cancel Ride',
          style: AppTextStyles.labelLarge(context)
              .copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}
