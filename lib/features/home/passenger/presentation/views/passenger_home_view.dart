import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/top_bar.dart';
import 'widgets/home_bottom_panel.dart';
import 'widgets/home_drawer.dart';

class PassengerHomeShell extends StatelessWidget {
  const PassengerHomeShell({
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
        menuScreen: const HomeDrawer(),
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

class PassengerHomeView extends StatelessWidget {
  const PassengerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: const SafeArea(
        child: Column(
          children: [
            TopBar(),
            HomeBottomPanel(),
          ],
        ),
      ),
    );
  }
}
