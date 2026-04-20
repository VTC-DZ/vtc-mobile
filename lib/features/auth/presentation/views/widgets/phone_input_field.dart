// lib/features/auth/presentation/views/widgets/phone_input_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Algeria-specific phone input field with DZ flag prefix pill and
/// animated error message.
class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    required this.onChanged,
    this.errorMessage,
    this.controller,
  });

  final ValueChanged<String> onChanged;

  /// When non-null and non-empty the border turns red and the message
  /// slides in underneath the field.
  final String? errorMessage;

  final TextEditingController? controller;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _isFocused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasError =>
      widget.errorMessage != null && widget.errorMessage!.isNotEmpty;

  Color _getBorderColor(BuildContext context) {
    if (_hasError) return AppColors.error;
    if (_isFocused) return AppColors.primary;
    return AppColors.borderDefault(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Input container ──────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56.h,
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _getBorderColor(context),
              width: 1.5.w,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 12.w),
              // Flag + country code pill
              _CountryPill(),
              SizedBox(width: 12.w),
              // Vertical divider
              Container(
                width: 1.w,
                height: 24.h,
                color: AppColors.borderDefault(context),
              ),
              SizedBox(width: 12.w),
              // Text field
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  keyboardType: TextInputType.phone,
                  maxLength: AppConstants.phoneMaxLength,
                  style: AppTextStyles.inputText(context),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(AppConstants.phoneMaxLength),
                  ],
                  decoration: InputDecoration(
                    hintText: AppConstants.phoneHint,
                    hintStyle: AppTextStyles.inputHint(context),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
            ],
          ),
        ),

        // ── Error message (animated slide-in) ────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: _hasError
              ? Padding(
                  padding: EdgeInsets.only(top: 6.h, left: 4.w),
                  child: Text(
                    widget.errorMessage!,
                    style: AppTextStyles.inputError(context),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// The 🇩🇿 DZ country-code pill displayed as a prefix inside the input.
class _CountryPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60.w,
      height: 32.h,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppConstants.countryFlag,
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(width: 4.w),
            Text(
              AppConstants.countryIso,
              style: AppTextStyles.bodySmall(context).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
