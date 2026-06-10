import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../features/ride/data/models/ride_models.dart';
import '../../../../../shared/widgets/top_bar.dart';
import '../cubit/passenger_home_cubit.dart';
import '../cubit/passenger_home_state.dart';
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
    return BlocListener<PassengerHomeCubit, PassengerHomeState>(
      listenWhen: (prev, curr) =>
          prev.activeRideStatus != curr.activeRideStatus,
      listener: (context, state) {
        if (state.activeRideStatus == ActiveRideStatus.foundRequest) {
          final request = state.activeRequest!;
          context.go(
            RouteNames.waitingOffers,
            extra: WaitingOffersArgs(
              proposedFare: request.proposedFare,
              response: CreateRideResponse(
                rideRequestId: request.rideRequestId,
                state: request.state,
                proposedFare: request.proposedFare,
                expiresAt: request.expiresAt,
                broadcastDriverCount: request.offerCount,
              ),
            ),
          );
          context.read<PassengerHomeCubit>().clearActiveRideStatus();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: SafeArea(
          child: Column(
            children: [
              const TopBar(),
              BlocBuilder<PassengerHomeCubit, PassengerHomeState>(
                buildWhen: (prev, curr) =>
                    prev.activeRideStatus != curr.activeRideStatus,
                builder: (context, state) {
                  if (state.activeRideStatus == ActiveRideStatus.foundRide) {
                    return _ActiveRideBanner(ride: state.activeRide!);
                  }
                  return const SizedBox.shrink();
                },
              ),
              const HomeBottomPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveRideBanner extends StatelessWidget {
  const _ActiveRideBanner({required this.ride});

  final ActiveRideSummary ride;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: navigate to ride tracking screen
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.primary, width: 1.5.w),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car_rounded,
                color: AppColors.primary, size: 20.w),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'You have an active ride — tap to view',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.primary, size: 20.w),
          ],
        ),
      ),
    );
  }
}
