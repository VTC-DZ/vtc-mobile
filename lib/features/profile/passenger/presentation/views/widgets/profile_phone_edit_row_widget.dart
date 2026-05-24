import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';

class ProfilePhoneEditRowWidget extends StatelessWidget {
  const ProfilePhoneEditRowWidget(
      {super.key, required this.onTap, required this.phone});

  final String phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final borderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                phone,
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
