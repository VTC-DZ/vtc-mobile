import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

import '../../../../../core/theme/app_colors.dart';
import 'widgets/driver_home_drawer.dart';

class DriverHomeShell extends StatelessWidget {
  const DriverHomeShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: ZoomDrawer(
        style: DrawerStyle.defaultStyle,
        menuScreen: const DriverHomeDrawer(),
        mainScreen: child,
        borderRadius: 30,
        showShadow: true,
        angle: 1,
        menuBackgroundColor: AppColors.drawerBackground(context),
        moveMenuScreen: false,
        slideWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
    );
  }
}
