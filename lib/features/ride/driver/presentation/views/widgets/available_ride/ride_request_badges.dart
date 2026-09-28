import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/driver_ride_models.dart';

String formatDistance(int meters) =>
    meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '$meters m';

/// Pink pill flagging a women-only ride request.
class FemaleOnlyBadge extends StatelessWidget {
  const FemaleOnlyBadge({super.key});

  static const Color _color = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.female_rounded, size: 14.w, color: _color),
          SizedBox(width: 3.w),
          Text(
            'Women',
            style: AppTextStyles.labelSmall(context).copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiet neutral pill surfacing the ride's vehicle category (icon + label).
class VehicleCategoryChip extends StatelessWidget {
  const VehicleCategoryChip({
    super.key,
    required this.category,
    this.iconSize = 14,
    this.hPad = 8,
    this.vPad = 4,
  });

  final VehicleCategory category;
  final double iconSize;
  final double hPad;
  final double vPad;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textSecondary(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad.w, vertical: vPad.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: iconSize.w, color: color),
          SizedBox(width: 3.w),
          Text(
            category.label,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
