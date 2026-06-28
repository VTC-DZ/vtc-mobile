import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../ride/driver/presentation/cubit/available_rides_cubit/available_rides_cubit.dart';
import '../../../../ride/driver/presentation/cubit/available_rides_cubit/available_rides_state.dart';
import '../../../../ride/driver/presentation/cubit/driver_availability_cubit/driver_availability_cubit.dart';
import '../../../../ride/driver/presentation/views/widgets/available_ride/broadcast_overlay.dart';
import '../cubit/driver_home_cubit.dart';
import '../cubit/driver_home_state.dart';
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

    // Shell-scoped listener: AvailableRidesCubit already receives the
    // `offer.accepted` socket frame on every driver screen, so react here (at
    // the shell) rather than only inside AvailableRidesView — this way the
    // driver is taken to the active ride no matter which screen is showing.
    return MultiBlocListener(
      listeners: [
        BlocListener<DriverHomeCubit, DriverHomeState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status &&
              curr.status == DriverHomeStatus.success,
          listener: (context, state) {
            context
                .read<DriverAvailabilityCubit>()
                .seed(state.profile!.isOnline);
          },
        ),
        BlocListener<AvailableRidesCubit, AvailableRidesState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status &&
              curr.status == AvailableRidesStatus.offerAccepted,
          listener: (context, state) {
            context.go(RouteNames.driverActiveRide);
          },
        ),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
      ),
    );
  }
}
