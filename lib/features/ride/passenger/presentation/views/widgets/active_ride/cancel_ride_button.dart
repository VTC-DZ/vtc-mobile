import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/cancel_ride_dialog.dart';
import '../../../../../shared/models/shared_ride_models.dart';

class CancelRideButton extends StatelessWidget {
  const CancelRideButton({super.key, required this.onCancel});

  /// Called with the reason the user picked in the cancel dialog.
  final ValueChanged<CancelReason> onCancel;

  Future<void> _showDialog(BuildContext context) async {
    final reason = await showCancelRideDialog(context);
    if (reason != null && context.mounted) {
      onCancel(reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        8.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 16.h,
      ),
      child: TextButton(
        onPressed: () => _showDialog(context),
        child: Text(
          'Cancel Ride',
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
