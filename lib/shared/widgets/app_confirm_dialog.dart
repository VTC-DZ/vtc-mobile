// lib/shared/widgets/app_confirm_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Shows a styled confirmation dialog and returns `true` if confirmed.
///
/// ```dart
/// final ok = await showAppConfirmDialog(
///   context: context,
///   title: 'Logout',
///   message: 'Are you sure you want to logout?',
///   confirmLabel: 'Logout',
///   isDestructive: true,
/// );
/// ```
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  bool isLoading = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      isLoading: isLoading,
    ),
  );
}

class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.isLoading = false,
    this.onConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final bool isLoading;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDestructive ? AppColors.error : AppColors.primary;

    return Center(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32.w),
          padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.headingMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: Material(
                  color: confirmColor,
                  borderRadius: BorderRadius.circular(12.r),
                  child: InkWell(
                    onTap: isLoading
                            ? null
                            : onConfirm ?? () => Navigator.of(context).pop(true),
                    borderRadius: BorderRadius.circular(12.r),
                    splashColor: AppColors.white.withValues(alpha: 0.2),
                    highlightColor: AppColors.white.withValues(alpha: 0.1),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              confirmLabel,
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
                    onTap: () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(12.r),
                    splashColor: confirmColor.withValues(alpha: 0.08),
                    highlightColor: confirmColor.withValues(alpha: 0.04),
                    child: Center(
                      child: Text(
                        cancelLabel,
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
