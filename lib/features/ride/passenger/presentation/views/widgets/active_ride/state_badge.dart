import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../driver/data/models/ride_socket_event.dart';

class RideStateBadge extends StatelessWidget {
  const RideStateBadge({super.key, required this.rideState});

  final RideState? rideState;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (rideState) {
      RideState.accepted => ('Driver is on the way', AppColors.primary),
      RideState.arrived => ('Driver has arrived', Colors.orange),
      RideState.inProgress => ('Ride in progress', Colors.green),
      _ => ('Waiting...', AppColors.textSecondary(context)),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10.w, color: color),
          SizedBox(width: 10.w),
          Text(
            label,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
