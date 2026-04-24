import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

class ChangeNumberBarWidget extends StatelessWidget {
  const ChangeNumberBarWidget({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Wrong number? ',
          style: AppTextStyles.bodySmall(context),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Change Number',
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
