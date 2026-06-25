import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../ride/driver/presentation/views/widgets/broadcast_overlay.dart';
import 'widgets/driver_home_drawer.dart';

class DriverHomeShell extends StatelessWidget {
  const DriverHomeShell({
    super.key,
    required this.child,
  });

  final Widget child;

  static const _hideOverlayRoutes = {
    RouteNames.availableRides,
    RouteNames.driverActiveRide,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPath = GoRouterState.of(context).uri.path;
    final showOverlay = !_hideOverlayRoutes.contains(currentPath);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Stack(
        children: [
          ZoomDrawer(
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
          if (showOverlay) const BroadcastOverlay(),
        ],
      ),
    );
  }
}
