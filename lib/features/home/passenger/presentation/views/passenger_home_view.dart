import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import 'widgets/home_bottom_panel.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_map_section.dart';
import 'widgets/home_top_bar.dart';

class PassengerHomeView extends StatelessWidget {
  const PassengerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppColors.background(context),
        drawer: const HomeDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              HomeTopBar(scaffoldKey: scaffoldKey),
              const Expanded(child: HomeMapSection()),
              const HomeBottomPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
