import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Rounded surface card with an optional bold [title] row (and [trailing]
/// widget beside it) — the building block of the ride-detail screen.
class RideDetailSection extends StatelessWidget {
  const RideDetailSection({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;

  /// Defaults to [AppColors.surface].
  final Color? color;

  /// Defaults to [AppColors.borderDefault].
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderColor ?? AppColors.borderDefault(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: AppTextStyles.labelLarge(context).copyWith(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: 14.h),
          ],
          child,
        ],
      ),
    );
  }
}
