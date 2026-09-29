import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../utils/date_formatter.dart';
import 'ride_detail_section.dart';
import 'ride_detail_step.dart';

/// Pickup → drop-off stops of a past ride on a dashed route rail, each with
/// the time the trip left or reached it when known.
class RideDetailAddressesCard extends StatelessWidget {
  const RideDetailAddressesCard({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.pickupTime,
    this.dropoffTime,
  });

  final String pickup;
  final String dropoff;

  /// ISO-8601 time the trip started (left the pickup); hidden when `null`.
  final String? pickupTime;

  /// ISO-8601 time the trip completed (reached the drop-off); hidden when
  /// `null`.
  final String? dropoffTime;

  @override
  Widget build(BuildContext context) {
    final lineColor = AppColors.textSecondary(context).withValues(alpha: 0.35);

    return RideDetailSection(
      title: 'Trip',
      child: Column(
        children: [
          RideDetailStep(
            isFirst: true,
            dashed: true,
            lineColor: lineColor,
            railWidth: 16,
            gap: 18,
            marker: Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 4.w),
              ),
            ),
            child: _Stop(label: 'Pickup', address: pickup, time: pickupTime),
          ),
          RideDetailStep(
            isLast: true,
            dashed: true,
            lineColor: lineColor,
            railWidth: 16,
            marker: Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            child: _Stop(
              label: 'Drop-off',
              address: dropoff,
              time: dropoffTime,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.label, required this.address, this.time});

  final String label;
  final String address;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final formattedTime = time == null ? '' : formatRideTime(time!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
            if (formattedTime.isNotEmpty)
              Text(
                formattedTime,
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          address.isEmpty ? '—' : address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: AppColors.text(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
