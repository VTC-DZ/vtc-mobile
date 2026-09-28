import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../ride_route_preview.dart';

/// Pickup → drop-off addresses of a past ride, in a detail-screen card.
class RideDetailAddressesCard extends StatelessWidget {
  const RideDetailAddressesCard({
    super.key,
    required this.pickup,
    required this.dropoff,
  });

  final String pickup;
  final String dropoff;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault(context), width: 1.w),
      ),
      child: RideRoutePreview(pickup: pickup, dropoff: dropoff),
    );
  }
}
