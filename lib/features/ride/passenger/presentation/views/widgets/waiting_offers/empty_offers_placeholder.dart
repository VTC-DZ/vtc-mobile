import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

class EmptyOffersPlaceholder extends StatelessWidget {
  const EmptyOffersPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Icon(
              Icons.search_rounded,
              size: 48.w,
              color: AppColors.textSecondary(context).withValues(alpha: 0.4),
            ),
            SizedBox(height: 12.h),
            Text(
              'Looking for nearby drivers…',
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
