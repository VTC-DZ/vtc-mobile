import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../utils/fare_formatter.dart';
import '../ride_detail/ride_detail_section.dart';

/// The agreed fare of the active ride, in large tabular figures.
class RideFareRow extends StatelessWidget {
  const RideFareRow({super.key, required this.fare});

  /// Whole DZD.
  final int fare;

  @override
  Widget build(BuildContext context) {
    return RideDetailSection(
      color: AppColors.primary.withValues(alpha: 0.07),
      borderColor: AppColors.primary.withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.payments_rounded,
              size: 20.w,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Agreed fare',
              style: AppTextStyles.labelMedium(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatFare(fare),
                  style: AppTextStyles.headingMedium(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: ' DZD',
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
