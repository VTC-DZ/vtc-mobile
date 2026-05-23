import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../core/theme/app_colors.dart';

class ProfileEditShimmerWidget extends StatelessWidget {
  const ProfileEditShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final baseColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40.h),
            _ShimmerBlock(width: 80.w, height: 14.h),
            SizedBox(height: 8.h),
            _ShimmerBlock(height: 52.h, radius: 12.r),
            SizedBox(height: 24.h),
            _ShimmerBlock(width: 60.w, height: 14.h),
            SizedBox(height: 8.h),
            _ShimmerBlock(height: 52.h, radius: 12.r),
            SizedBox(height: 24.h),
            _ShimmerBlock(width: 100.w, height: 14.h),
            SizedBox(height: 8.h),
            _ShimmerBlock(height: 52.h, radius: 12.r),
            SizedBox(height: 24.h),
            _ShimmerBlock(width: 120.w, height: 14.h),
            SizedBox(height: 8.h),
            _ShimmerBlock(height: 52.h, radius: 12.r),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({this.width, required this.height, this.radius});

  final double? width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius ?? 6.r),
      ),
    );
  }
}
