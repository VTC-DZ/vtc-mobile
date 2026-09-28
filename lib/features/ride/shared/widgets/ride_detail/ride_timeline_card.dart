import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../utils/date_formatter.dart';

/// Chronological list of a ride's lifecycle timestamps. Steps the ride never
/// reached (`null`) are left out.
class RideTimelineCard extends StatelessWidget {
  const RideTimelineCard({
    super.key,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  final String? acceptedAt;
  final String? arrivedAt;
  final String? startedAt;
  final String? completedAt;
  final String? cancelledAt;

  @override
  Widget build(BuildContext context) {
    final events = <({String label, IconData icon, String at})>[
      if (acceptedAt != null)
        (label: 'Accepted', icon: Icons.handshake_outlined, at: acceptedAt!),
      if (arrivedAt != null)
        (label: 'Arrived', icon: Icons.flag_outlined, at: arrivedAt!),
      if (startedAt != null)
        (label: 'Started', icon: Icons.local_taxi_rounded, at: startedAt!),
      if (completedAt != null)
        (
          label: 'Completed',
          icon: Icons.check_circle_rounded,
          at: completedAt!,
        ),
      if (cancelledAt != null)
        (label: 'Cancelled', icon: Icons.cancel_rounded, at: cancelledAt!),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault(context), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: AppTextStyles.labelMedium(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          for (final (index, event) in events.indexed) ...[
            _TimelineRow(event: event),
            if (index != events.length - 1) SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});

  final ({String label, IconData icon, String at}) event;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(event.icon, size: 18.w, color: AppColors.textSecondary(context)),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            event.label,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
        Text(
          formatRideDateTime(event.at),
          style: AppTextStyles.labelSmall(context).copyWith(
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}
