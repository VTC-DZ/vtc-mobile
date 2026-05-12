import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/route_names.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../auth/data/repo/auth_repository.dart';
import '../../cubit/passenger_home_cubit.dart';
import '../../cubit/passenger_home_state.dart';

const int _profileIndex = 1;
const int _logoutIndex = 8;

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = <_DrawerMenuItemData>[
      const _DrawerMenuItemData(Icons.home_outlined, 'Home'),
      const _DrawerMenuItemData(Icons.person_outline_rounded, 'Profile'),
      const _DrawerMenuItemData(Icons.directions_car_rounded, 'My Rides'),
      const _DrawerMenuItemData(Icons.bookmark_border_rounded, 'Saved Places'),
      const _DrawerMenuItemData(Icons.credit_card_rounded, 'Payment'),
      const _DrawerMenuItemData(Icons.local_offer_outlined, 'Promotions'),
    ];

    final supportItems = <_DrawerMenuItemData>[
      const _DrawerMenuItemData(Icons.settings_outlined, 'Settings'),
      const _DrawerMenuItemData(Icons.help_outline_rounded, 'Help & Support'),
    ];

    return BlocBuilder<PassengerHomeCubit, PassengerHomeState>(
      builder: (context, state) {
        final selectedIndex = state.selectedIndex;

        return Scaffold(
          backgroundColor: AppColors.drawerBackground(context),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDrawerHeader(context, state),
                  SizedBox(height: 18.h),
                  ..._buildMenuSection(
                    menuItems,
                    selectedIndex: selectedIndex,
                    context: context,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: const _DashedDivider(),
                  ),
                  ..._buildMenuSection(
                    supportItems,
                    startIndex: menuItems.length,
                    selectedIndex: selectedIndex,
                    context: context,
                  ),
                  SizedBox(height: 14.h),
                  _DrawerItem(
                    icon: Icons.logout_outlined,
                    label: 'Logout',
                    color: AppColors.error,
                    isSelected: selectedIndex == _logoutIndex,
                    onTap: () => _onMenuItemTap(context, _logoutIndex),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onMenuItemTap(BuildContext context, int index) {
    if (index == _logoutIndex) {
      context.read<PassengerHomeCubit>().updateSelectedIndex(index);
      ZoomDrawer.of(context)?.close();
      const AuthRepository().logout();
      return;
    }

    final route = index == _profileIndex
        ? RouteNames.passengerProfileEdit
        : RouteNames.passengerHome;
    final selectedIndex = index == _profileIndex ? _profileIndex : 0;

    context.read<PassengerHomeCubit>().updateSelectedIndex(selectedIndex);
    ZoomDrawer.of(context)?.close();
    context.go(route);
  }

  List<Widget> _buildMenuSection(
    List<_DrawerMenuItemData> items, {
    int startIndex = 0,
    required int selectedIndex,
    required BuildContext context,
  }) {
    return List.generate(items.length, (offset) {
      final index = startIndex + offset;
      final item = items[offset];

      return _DrawerItem(
        icon: item.icon,
        label: item.label,
        isSelected: selectedIndex == index,
        onTap: () => _onMenuItemTap(context, index),
      );
    });
  }

  Widget _buildDrawerHeader(BuildContext context, PassengerHomeState state) {
    final name = state.profile?.fullName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 70.w,
          height: 70.w,
          decoration: BoxDecoration(
            color:
                AppColors.isDark(context) ? AppColors.white : AppColors.black,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 24.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.person_rounded,
                color: AppColors.isDark(context)
                    ? AppColors.black
                    : AppColors.white,
                size: 36.w,
              ),
              Positioned(
                right: 9.w,
                bottom: 9.w,
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.drawerBackground(context),
                      width: 2.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          name != null ? 'Hello, $name!' : 'Hello, Passenger!',
          style: AppTextStyles.headingMedium(context).copyWith(
            color: AppColors.drawerText(context),
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Ready for your next ride?',
          style: AppTextStyles.bodySmall(context).copyWith(
            color: AppColors.drawerTextMuted(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DrawerMenuItemData {
  const _DrawerMenuItemData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 5.h,
      width: double.infinity,
      child: Row(
        children: List.generate(
          40,
          (index) => Expanded(
            child: Container(
              height: 2.h,
              color: index.isEven
                  ? Colors.transparent
                  : AppColors.drawerDivider(context),
            ),
          ),
        ),
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
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? AppColors.drawerText(context);
    final itemColor = isSelected ? baseColor : baseColor.withValues(alpha: 0.7);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      splashColor: AppColors.drawerText(context).withValues(alpha: 0.08),
      highlightColor: AppColors.drawerText(context).withValues(alpha: 0.04),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.drawerItemSelected(context)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24.w, color: itemColor),
            SizedBox(width: 20.w),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium(context).copyWith(
                  color: itemColor,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
