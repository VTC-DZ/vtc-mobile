import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../utils/date_formatter.dart';
import 'ride_detail_section.dart';
import 'ride_detail_step.dart';

typedef _TimelineEvent = ({
  String label,
  IconData icon,
  String at,
  Color color,
});

/// Chronological stepper of a ride's lifecycle timestamps. Steps the ride
/// never reached (`null`) are left out; the last step — where the ride ended
/// up — is drawn filled.
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
    const reached = AppColors.primary;
    final events = <_TimelineEvent>[
      if (acceptedAt != null)
        (
          label: 'Offer accepted',
          icon: Icons.handshake_rounded,
          at: acceptedAt!,
          color: reached,
        ),
      if (arrivedAt != null)
        (
          label: 'Driver arrived',
          icon: Icons.flag_rounded,
          at: arrivedAt!,
          color: reached,
        ),
      if (startedAt != null)
        (
          label: 'Trip started',
          icon: Icons.local_taxi_rounded,
          at: startedAt!,
          color: reached,
        ),
      if (completedAt != null)
        (
          label: 'Trip completed',
          icon: Icons.check_rounded,
          at: completedAt!,
          color: reached,
        ),
      if (cancelledAt != null)
        (
          label: 'Ride cancelled',
          icon: Icons.close_rounded,
          at: cancelledAt!,
          color: AppColors.error,
        ),
    ];
    if (events.isEmpty) return const SizedBox.shrink();

    final day = formatRideDate(events.first.at);

    return RideDetailSection(
      title: 'Timeline',
      trailing: day.isEmpty
          ? null
          : Text(
              day,
              style: AppTextStyles.labelSmall(context).copyWith(
                color: AppColors.textSecondary(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
      child: Column(
        children: [
          for (final (index, event) in events.indexed)
            RideDetailStep(
              isFirst: index == 0,
              isLast: index == events.length - 1,
              lineColor: AppColors.primary.withValues(alpha: 0.3),
              railWidth: 28,
              markerTop: 0,
              gap: 14,
              marker: _Marker(
                event: event,
                filled: index == events.length - 1,
              ),
              child: _EventRow(event: event),
            ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.event, required this.filled});

  final _TimelineEvent event;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: filled ? event.color : event.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        boxShadow: filled
            ? [
                BoxShadow(
                  color: event.color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        event.icon,
        size: 15.w,
        color: filled ? AppColors.white : event.color,
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final _TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    // Vertically centred on the 28px marker.
    return SizedBox(
      height: 28.w,
      child: Row(
        children: [
          Expanded(
            child: Text(
              event.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.text(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatRideTime(event.at),
            style: AppTextStyles.labelMedium(context).copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
