import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/route_names.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../auth/data/repo/auth_repository.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background(context),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context),
            SizedBox(height: 8.h),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                children: [
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    onTap: () async {
                      Navigator.pop(context);

                      context.push(
                        RouteNames.passengerProfileEdit,
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.directions_car_rounded,
                    label: 'My Rides',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.bookmark_border_rounded,
                    label: 'Saved Places',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.credit_card_rounded,
                    label: 'Payment',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.local_offer_outlined,
                    label: 'Promotions',
                    onTap: () => Navigator.pop(context),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Divider(
                      color: AppColors.borderDefault(context),
                      height: 1,
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  const AuthRepository().logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.5),
                width: 2.w,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.white,
              size: 30.w,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Welcome!',
            style: AppTextStyles.headingSmall(context).copyWith(
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'passenger@example.com',
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.text(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 22.w, color: itemColor),
            SizedBox(width: 16.w),
            Text(
              label,
              style: AppTextStyles.labelMedium(context).copyWith(
                color: itemColor,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
