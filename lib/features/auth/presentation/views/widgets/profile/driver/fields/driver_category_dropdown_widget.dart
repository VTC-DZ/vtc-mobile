import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../cubit/driver_profile_cubit/driver_profile_state.dart';

class DriverCategoryDropdownWidget extends StatelessWidget {
  const DriverCategoryDropdownWidget({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    required this.enabled,
  });

  final VehicleCategory? selectedCategory;
  final ValueChanged<VehicleCategory> onChanged;
  final bool enabled;

  static const _options = VehicleCategory.values;
  static const _labels = {
    VehicleCategory.car: 'Car',
    VehicleCategory.motorcycle: 'Motorcycle',
    VehicleCategory.van: 'Van',
  };

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault(ctx),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'Vehicle Type',
                  style: AppTextStyles.headingSmall(ctx),
                ),
              ),
              SizedBox(height: 8.h),
              ..._options.map((cat) {
                final isSelected = cat == selectedCategory;
                return ListTile(
                  title: Text(
                    _labels[cat]!,
                    style: AppTextStyles.bodyMedium(ctx).copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.text(ctx),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 20.w)
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onChanged(cat);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedCategory != null;

    return GestureDetector(
      onTap: enabled ? () => _openSheet(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56.h,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.borderDefault(context),
            width: 1.5.w,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 20.w,
                color: AppColors.textSecondary(context),
              ),
              SizedBox(width: 12.w),
              Text(
                hasValue ? _labels[selectedCategory!]! : 'Select type',
                style: hasValue
                    ? AppTextStyles.inputText(context)
                    : AppTextStyles.inputHint(context),
              ),
              const Spacer(),
              Icon(
                Icons.expand_more_rounded,
                size: 20.w,
                color: AppColors.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
