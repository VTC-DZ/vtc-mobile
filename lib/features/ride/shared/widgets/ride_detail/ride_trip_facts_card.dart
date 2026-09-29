import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Distance and duration of a finished trip as side-by-side stat tiles. A
/// missing value renders as `—`.
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
      : (distanceMeters! / 1000).toStringAsFixed(1);

  String get _duration =>
      durationSeconds == null ? '—' : '${(durationSeconds! / 60).round()}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.route_rounded,
            label: 'Distance',
            value: _distance,
            unit: distanceMeters == null ? null : 'km',
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _StatTile(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: _duration,
            unit: durationSeconds == null ? null : 'min',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.w, color: AppColors.primary),
          ),
          SizedBox(height: 12.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTextStyles.headingMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (unit != null) ...[
                  SizedBox(width: 4.w),
                  Text(
                    unit!,
                    style: AppTextStyles.labelMedium(context).copyWith(
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
