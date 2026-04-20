import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

class ProfileEmailFieldWidget extends StatelessWidget {
  const ProfileEmailFieldWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.error,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final String error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasError = error.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : focusNode.hasFocus
                      ? AppColors.primary
                      : AppColors.borderDefault(context),
              width: 1.5.w,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.emailAddress,
            onChanged: onChanged,
            style: AppTextStyles.inputText(context),
            decoration: InputDecoration(
              hintText: 'your@email.com (optional)',
              hintStyle: AppTextStyles.inputHint(context),
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                color: hasError
                    ? AppColors.error
                    : AppColors.textSecondary(context),
                size: 20.w,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: hasError
              ? Padding(
                  padding: EdgeInsets.only(top: 6.h, left: 4.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13.w,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        error,
                        style: AppTextStyles.inputError(context),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
