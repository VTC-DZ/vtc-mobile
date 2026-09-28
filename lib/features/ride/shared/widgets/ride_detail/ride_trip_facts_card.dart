import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Distance and duration of a finished trip, side by side. A missing value
/// renders as `—`.
class RideTripFactsCard extends StatelessWidget {
  const RideTripFactsCard({
    super.key,
    this.distanceMeters,
    this.durationSeconds,
  });

  final int? distanceMeters;
  final int? durationSeconds;

  String get _distance => distanceMeters == null
      ? '—'
      : '${(distanceMeters! / 1000).toStringAsFixed(1)} km';

  String get _duration =>
      durationSeconds == null ? '—' : '${(durationSeconds! / 60).round()} min';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault(context), width: 1.w),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Fact(
              icon: Icons.route_rounded,
              label: 'Distance',
              value: _distance,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _Fact(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: _duration,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.w, color: AppColors.primary),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
