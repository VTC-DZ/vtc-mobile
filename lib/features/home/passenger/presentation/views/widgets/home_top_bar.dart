import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          _IconButton(
            onTap: () => scaffoldKey.currentState?.openDrawer(),
            child: Icon(
              Icons.menu_rounded,
              size: 22.w,
              color: AppColors.text(context),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good to see you 👋', style: AppTextStyles.bodySmall(context)),
                Text('Where to?', style: AppTextStyles.headingSmall(context)),
              ],
            ),
          ),
          _IconButton(
            onTap: () {},
            child: Icon(
              Icons.notifications_none_rounded,
              size: 22.w,
              color: AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.borderDefault(context),
            width: 1.5.w,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
