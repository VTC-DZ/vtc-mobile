import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../utils/name_initials.dart';

/// Initials circle for a ride participant (no photos are exposed between
/// drivers and passengers).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 44});

  final String name;

  /// Diameter in design pixels (scaled with `.w`).
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Text(
        initialsOf(name),
        style: AppTextStyles.labelLarge(context).copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: (size * 0.36).sp,
        ),
      ),
    );
  }
}

/// Licence-plate look: light plate, dark rim, bold tabular characters.
/// Kept light in dark mode too, like a real plate.
class VehiclePlateChip extends StatelessWidget {
  const VehiclePlateChip({super.key, required this.plate, this.large = false});

  final String plate;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (large ? 10 : 6).w,
        vertical: (large ? 4 : 2).h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F2),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: AppColors.black, width: 1.2),
      ),
      child: Text(
        plate,
        maxLines: 1,
        style: AppTextStyles.labelSmall(context).copyWith(
          color: AppColors.black,
          fontWeight: FontWeight.w800,
          fontSize: (large ? 13 : 11).sp,
          letterSpacing: 0.6,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
