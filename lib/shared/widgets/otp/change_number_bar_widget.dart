import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';

class ChangeNumberBarWidget extends StatelessWidget {
  const ChangeNumberBarWidget({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.otpWrongNumber,
          style: AppTextStyles.bodySmall(context),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            AppStrings.otpChangeNumber,
            style: AppTextStyles.labelMedium(context).copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
