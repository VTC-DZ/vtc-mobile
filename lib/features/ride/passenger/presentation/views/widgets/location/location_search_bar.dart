import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

class LocationSearchBar extends StatelessWidget {
  const LocationSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.isLoading,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background(context),
      borderRadius: BorderRadius.circular(12.r),
      elevation: 2,
      child: SizedBox(
        height: 44.w,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          style: AppTextStyles.bodyMedium(context)
              .copyWith(color: AppColors.text(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium(context),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18.w,
              color: AppColors.textSecondary(context),
            ),
            suffixIcon: isLoading
                ? Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16.w,
                          color: AppColors.textSecondary(context),
                        ),
                        onPressed: onClear,
                      )
                    : null,
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
          ),
        ),
      ),
    );
  }
}
