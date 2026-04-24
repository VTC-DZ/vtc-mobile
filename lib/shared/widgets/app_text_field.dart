import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.error = '',
    this.enabled = true,
    this.unfocusOnTapOutside = true,
  });

  final TextEditingController controller;
  final String? hintText;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTapOutside;
  final bool unfocusOnTapOutside;
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
              color:
                  hasError ? AppColors.error : AppColors.borderDefault(context),
              width: 1.5.w,
            ),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            onTapOutside: (_) {
              if (unfocusOnTapOutside) FocusManager.instance.primaryFocus?.unfocus();
              onTapOutside?.call();
            },
            style: AppTextStyles.inputText(context),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.inputHint(context),
              prefixIcon: prefixIcon != null
                  ? IconTheme(
                      data: IconThemeData(
                        color: hasError
                            ? AppColors.error
                            : AppColors.textSecondary(context),
                        size: 20.w,
                      ),
                      child: prefixIcon!,
                    )
                  : null,
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
