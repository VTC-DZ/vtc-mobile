import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/driver_ride_models.dart';

/// Human-friendly distance: `850 m`, `3.4 km`, `2 km`, `23 km`.
///
/// The number and unit are joined by a non-breaking space so the unit never
/// wraps onto its own line.
String formatDistance(int meters) {
  const nbsp = ' ';
  if (meters < 1000) {
    final rounded = meters < 10 ? meters : (meters / 10).round() * 10;
    // Rounding 995+ m up lands on 1000 — show it as kilometres.
    if (rounded < 1000) return '$rounded${nbsp}m';
  }
  final km = meters / 1000;
  if (km >= 10) return '${km.round()}${nbsp}km';
  final oneDecimal = km.toStringAsFixed(1);
  final trimmed = oneDecimal.endsWith('.0')
      ? oneDecimal.substring(0, oneDecimal.length - 2)
      : oneDecimal;
  return '$trimmed${nbsp}km';
}

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
