import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';

class MapButton extends StatelessWidget {
  const MapButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background(context),
      borderRadius: BorderRadius.circular(12.r),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: SizedBox(
          width: 44.w,
          height: 44.w,
          child: Icon(icon, size: 20.w, color: AppColors.text(context)),
        ),
      ),
    );
  }
}
