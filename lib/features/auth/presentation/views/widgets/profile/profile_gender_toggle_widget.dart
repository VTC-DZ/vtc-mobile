import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/gender.dart';

class ProfileGenderToggleWidget extends StatelessWidget {
  const ProfileGenderToggleWidget({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  final Gender? selected;
  final ValueChanged<Gender> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GenderChip(
            label: 'Male',
            icon: Icons.male_rounded,
            isSelected: selected == Gender.male,
            onTap: enabled ? () => onChanged(Gender.male) : null,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _GenderChip(
            label: 'Female',
            icon: Icons.female_rounded,
            isSelected: selected == Gender.female,
            onTap: enabled ? () => onChanged(Gender.female) : null,
          ),
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56.h,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.borderDefault(context),
            width: isSelected ? 2.w : 1.5.w,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.w,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary(context),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: AppTextStyles.labelMedium(context).copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
