import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/top_bar.dart';
import '../cubit/driver_home_cubit.dart';
import '../cubit/driver_home_state.dart';

class DriverHomeView extends StatelessWidget {
  const DriverHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverHomeCubit, DriverHomeState>(
      listenWhen: (prev, curr) =>
          prev.activeRideCheckStatus != curr.activeRideCheckStatus,
      listener: (context, state) {
        if (state.activeRideCheckStatus == DriverActiveRideCheckStatus.found) {
          context.go(RouteNames.driverActiveRide);
          context.read<DriverHomeCubit>().clearActiveRideCheckStatus();
        }
      },
      child: BlocBuilder<DriverHomeCubit, DriverHomeState>(
        buildWhen: (prev, curr) =>
            prev.activeRideCheckStatus != curr.activeRideCheckStatus,
        builder: (context, state) {
          if (state.activeRideCheckStatus ==
              DriverActiveRideCheckStatus.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            backgroundColor: AppColors.background(context),
            body: const SafeArea(
              child: Column(
                children: [
                  TopBar(
                    title: 'Driver Mode',
                    subtitle: 'Ready to drive',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
