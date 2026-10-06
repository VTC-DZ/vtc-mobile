// lib/shared/widgets/app_logo_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_images.dart';

/// Branded square logo used on auth screens.
class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Image.asset(
        AppImages.logo,
        width: 64.w,
        height: 64.w,
        fit: BoxFit.contain,
        semanticLabel: AppConstants.appName,
      ),
    );
  }
}
