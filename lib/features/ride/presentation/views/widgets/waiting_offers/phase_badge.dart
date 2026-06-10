import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

class PhaseBadge extends StatelessWidget {
  const PhaseBadge({
    super.key,
    required this.phase,
    required this.broadcastCount,
    required this.offerCount,
  });

  final String phase;
  final int broadcastCount;
  final int offerCount;

  @override
  Widget build(BuildContext context) {
    final isRequested = phase == 'REQUESTED';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (isRequested)
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            Icon(Icons.local_offer_rounded,
                size: 18.w, color: AppColors.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              isRequested
                  ? 'Broadcasting to $broadcastCount driver${broadcastCount == 1 ? '' : 's'}…'
                  : '$offerCount offer${offerCount == 1 ? '' : 's'} received',
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
