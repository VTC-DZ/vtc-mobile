// lib/features/auth/presentation/views/widgets/profile/driver/fields/driver_category_dropdown_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../../shared/widgets/app_text_field.dart';
import '../../../../../cubit/driver_profile_cubit/driver_profile_state.dart';

class DriverCategoryDropdownWidget extends StatefulWidget {
  const DriverCategoryDropdownWidget({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    required this.enabled,
  });

  final VehicleCategory? selectedCategory;
  final ValueChanged<VehicleCategory> onChanged;
  final bool enabled;

  @override
  State<DriverCategoryDropdownWidget> createState() =>
      _DriverCategoryDropdownWidgetState();
}

class _DriverCategoryDropdownWidgetState
    extends State<DriverCategoryDropdownWidget> {
  late final TextEditingController _controller;

  static const _options = VehicleCategory.values;
  static const _labels = {
    VehicleCategory.car: 'Car',
    VehicleCategory.motorcycle: 'Motorcycle',
    VehicleCategory.van: 'Van',
  };

  static const _icons = {
    VehicleCategory.car: Icons.directions_car_rounded,
    VehicleCategory.motorcycle: Icons.two_wheeler_rounded,
    VehicleCategory.van: Icons.airport_shuttle_rounded,
  };

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getText());
  }

  @override
  void didUpdateWidget(covariant DriverCategoryDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _controller.text = _getText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getText() {
    if (widget.selectedCategory == null) return '';
    return _labels[widget.selectedCategory!] ?? '';
  }

  void _openSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SizedBox(height: 8.h),

                SizedBox(height: 16.h),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColors.text(ctx),
                      AppColors.textSecondary(ctx).withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Select Vehicle Type',
                    style: AppTextStyles.headingSmall(ctx).copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: _options.map((cat) {
                    final isSelected = cat == widget.selectedCategory;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            widget.onChanged(cat);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(vertical: 24.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.text(ctx).withValues(alpha: 0.04)
                                  : AppColors.surface(ctx),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.text(ctx)
                                    : AppColors.borderDefault(ctx),
                                width: isSelected ? 2.w : 1.w,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.text(ctx)
                                            .withValues(alpha: 0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _icons[cat],
                                  size: 32.w,
                                  color: isSelected
                                      ? AppColors.text(ctx)
                                      : AppColors.textSecondary(ctx),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  _labels[cat]!,
                                  style: AppTextStyles.bodyMedium(ctx).copyWith(
                                    color: isSelected
                                        ? AppColors.text(ctx)
                                        : AppColors.textSecondary(ctx),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      readOnly: true,
      onTap: widget.enabled ? _openSheet : null,
      enabled: widget.enabled,
      hintText: 'Select type',
      prefixIcon: const Icon(Icons.directions_car_outlined),
      suffixIcon: const Icon(Icons.expand_more_rounded),
    );
  }
}
