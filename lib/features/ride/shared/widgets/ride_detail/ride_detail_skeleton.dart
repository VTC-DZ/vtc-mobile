import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';

/// Shimmering placeholder blocks shaped like the ride-detail sections, shown
/// while the detail endpoint is loading.
class RideDetailSkeleton extends StatelessWidget {
  const RideDetailSkeleton({super.key, this.includeSummary = false});

  /// Also mimic the summary, person and trip blocks — for a screen that has
  /// nothing to show yet (the driver's).
  final bool includeSummary;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final gap = SizedBox(height: 12.h);

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E2D8),
      highlightColor:
          isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF7F5F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (includeSummary) ...[
            Row(
              children: [
                _Block(width: 92.w, height: 24.h, radius: 8.r),
                SizedBox(width: 6.w),
                _Block(width: 64.w, height: 24.h, radius: 8.r),
              ],
            ),
            SizedBox(height: 16.h),
            _Block(width: 70.w, height: 12.h),
            SizedBox(height: 8.h),
            _Block(width: 160.w, height: 36.h),
            SizedBox(height: 10.h),
            _Block(width: 130.w, height: 12.h),
            SizedBox(height: 20.h),
          ],
          Row(
            children: [
              Expanded(child: _Block(height: 104.h, radius: 16.r)),
              SizedBox(width: 10.w),
              Expanded(child: _Block(height: 104.h, radius: 16.r)),
            ],
          ),
          if (includeSummary) ...[
            gap,
            _Block(height: 132.h, radius: 16.r),
            gap,
            _Block(height: 84.h, radius: 16.r),
          ],
          gap,
          _Block(height: 180.h, radius: 16.r),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({this.width, required this.height, this.radius});

  final double? width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius ?? 6.r),
      ),
    );
  }
}
