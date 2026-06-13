import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

class LocationPickerCard extends StatelessWidget {
  const LocationPickerCard({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.address,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String? address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasLocation = address != null && address!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: hasLocation
                ? iconColor.withValues(alpha: 0.5)
                : AppColors.borderDefault(context),
            width: hasLocation ? 1.5.w : 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18.w, color: iconColor),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSmall(context).copyWith(
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    hasLocation ? address! : 'Tap to set location',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: hasLocation
                          ? AppColors.text(context)
                          : AppColors.textSecondary(context),
                      fontWeight:
                          hasLocation ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              hasLocation
                  ? Icons.edit_location_alt_rounded
                  : Icons.map_rounded,
              size: 20.w,
              color: hasLocation
                  ? iconColor
                  : AppColors.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }
}
