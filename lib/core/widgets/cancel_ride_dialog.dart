import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../features/ride/passenger/data/models/passenger_ride_models.dart';

Future<CancelReason?> showCancelRideDialog(BuildContext context) {
  return showDialog<CancelReason>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => const _CancelRideDialog(),
  );
}

class _CancelRideDialog extends StatefulWidget {
  const _CancelRideDialog();

  @override
  State<_CancelRideDialog> createState() => _CancelRideDialogState();
}

class _CancelRideDialogState extends State<_CancelRideDialog> {
  CancelReason? _selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32.w),
          padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancel Ride',
                style: AppTextStyles.headingMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Please select a reason',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              SizedBox(height: 20.h),
              ...CancelReason.values.map((reason) => _ReasonRow(
                    reason: reason,
                    isSelected: _selected == reason,
                    onTap: () => setState(() => _selected = reason),
                  )),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: Material(
                  color: _selected != null
                      ? AppColors.error
                      : AppColors.error.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12.r),
                  child: InkWell(
                    onTap: _selected == null
                        ? null
                        : () => Navigator.of(context).pop(_selected),
                    borderRadius: BorderRadius.circular(12.r),
                    splashColor: AppColors.white.withValues(alpha: 0.2),
                    child: Center(
                      child: Text(
                        'Confirm Cancellation',
                        style: AppTextStyles.labelMedium(context).copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(null),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Center(
                      child: Text(
                        'Keep Ride',
                        style: AppTextStyles.labelMedium(context).copyWith(
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final CancelReason reason;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDefault(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason.label,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.text(context),
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.borderDefault(context),
                  width: isSelected ? 5 : 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
