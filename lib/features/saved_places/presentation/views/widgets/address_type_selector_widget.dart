import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../saved_places/data/address_model.dart';

class AddressTypeSelectorWidget extends StatelessWidget {
  const AddressTypeSelectorWidget({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AddressType selected;
  final ValueChanged<AddressType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AddressType.values.map((type) {
        final isSelected = type == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: 52.h,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16.r),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: AppColors.borderDefault(context),
                        ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12.r,
                            offset: Offset(0, 4.h),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        _iconFor(type),
                        size: 20.w,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textSecondary(context),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      type.name.capitalize(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(AddressType type) => switch (type) {
        AddressType.home => Icons.home_outlined,
        AddressType.work => Icons.work_outline_rounded,
        AddressType.other => Icons.location_on_outlined,
      };
}

extension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}
