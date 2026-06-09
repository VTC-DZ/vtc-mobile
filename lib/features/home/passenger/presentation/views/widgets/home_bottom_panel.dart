import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/route_names.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

class HomeBottomPanel extends StatelessWidget {
  const HomeBottomPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 20.r,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.borderDefault(context),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 16.h),

          // Search bar
          _SearchBar(),

          SizedBox(height: 16.h),

          // Quick destinations row
          Row(
            children: [
              _QuickDestination(
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () {},
              ),
              SizedBox(width: 10.w),
              _QuickDestination(
                icon: Icons.work_rounded,
                label: 'Work',
                onTap: () {},
              ),
              SizedBox(width: 10.w),
              _QuickDestination(
                icon: Icons.star_rounded,
                label: 'Saved',
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.rideRequest),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16.r),
          border:
              Border.all(color: AppColors.borderDefault(context), width: 1.5.w),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                size: 20.w, color: AppColors.textSecondary(context)),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Where do you want to go?',
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.near_me_rounded,
                  size: 16.w, color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDestination extends StatelessWidget {
  const _QuickDestination({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(12.r),
            border:
                Border.all(color: AppColors.borderDefault(context), width: 1.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20.w, color: AppColors.primary),
              SizedBox(height: 6.h),
              Text(label, style: AppTextStyles.labelSmall(context)),
            ],
          ),
        ),
      ),
    );
  }
}
