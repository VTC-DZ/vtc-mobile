import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/shared_ride_models.dart';

class RideRouteCard extends StatelessWidget {
  const RideRouteCard({
    super.key,
    required this.pickup,
    required this.dropoff,
  });

  final CoordinatePoint pickup;
  final CoordinatePoint dropoff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteIndicator(),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AddressRow(
                  label: 'Pickup',
                  address: pickup.address,
                ),
                SizedBox(height: 18.h),
                _AddressRow(
                  label: 'Dropoff',
                  address: dropoff.address,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 2.h),
        Container(
          width: 10.w,
          height: 10.w,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 4.h),
        ...List.generate(
          4,
          (i) => Container(
            width: 2.w,
            height: 5.h,
            margin: EdgeInsets.only(bottom: 3.h),
            decoration: BoxDecoration(
              color: AppColors.borderDefault(context),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
        ),
        Container(
          width: 10.w,
          height: 10.w,
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.label, required this.address});

  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          address,
          style: AppTextStyles.bodyMedium(context)
              .copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
