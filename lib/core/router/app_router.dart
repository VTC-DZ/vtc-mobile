import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/repo/auth_repository.dart';
import '../../features/auth/data/repo/profile_repository.dart';
import '../../features/auth/presentation/cubit/otp_cubit/otp_cubit.dart';
import '../../features/auth/presentation/cubit/passenger_profile_cubit/passenger_profile_cubit.dart';
import '../../features/auth/presentation/cubit/phone_cubit/phone_cubit.dart';
import '../../features/auth/presentation/views/mode_selection_view.dart';
import '../../features/auth/presentation/views/otp_verification_view.dart';
import '../../features/auth/presentation/views/passenger/passenger_profile_view.dart';
import '../../features/auth/presentation/views/phone_entry_view.dart';
import '../../features/auth/presentation/cubit/driver_profile_cubit/driver_profile_cubit.dart';
import '../../features/auth/presentation/views/driver/driver_pending_review_view.dart';
import '../../features/auth/presentation/views/driver/driver_registration_view.dart';
import '../../features/auth/presentation/views/driver/driver_rejection_view.dart';
import '../../features/home/passenger/presentation/cubit/passenger_home_cubit.dart';
import '../../features/home/passenger/presentation/views/passenger_home_view.dart';
import '../../features/home/profile/passenger/presentation/cubit/passenger_profile_edit_cubit.dart';
import '../../features/home/profile/passenger/presentation/views/passenger_profile_edit_view.dart';
import '../network/dio_client.dart';
import 'route_names.dart';

final class AppRouter {
  AppRouter._();

  static const _repository = AuthRepository();
  static const _profileRepository = ProfileRepository();

  static final GoRouter router = GoRouter(
    initialLocation: DioClient.isLoggedIn ? RouteNames.passengerHome : RouteNames.phone,
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Page not found')),
    ),
    routes: [
      GoRoute(
        path: RouteNames.phone,
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<PhoneCubit>(
            create: (_) => PhoneCubit(_repository),
            child: const PhoneEntryView(),
          );
        },
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (BuildContext context, GoRouterState state) {
          final phone = state.extra is String ? state.extra as String : '';
          return BlocProvider<OtpCubit>(
            create: (_) => OtpCubit(_repository, phoneNumber: phone),
            child: const OtpVerificationView(),
          );
        },
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (BuildContext context, GoRouterState state) {
          // Generic home placeholder — replaced per user type in Story 7+.
          return const Scaffold(
            body: Center(child: Text('Home — Story 7+')),
          );
        },
      ),
      GoRoute(
        path: RouteNames.modeSelection,
        builder: (BuildContext context, GoRouterState state) {
          return const ModeSelectionView();
        },
      ),
      GoRoute(
        path: RouteNames.passengerProfile,
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<PassengerProfileCubit>(
            create: (_) => PassengerProfileCubit(_profileRepository),
            child: const PassengerProfileView(),
          );
        },
      ),
      ShellRoute(
          builder: (context, state, child) => BlocProvider(
                create: (context) =>
                    PassengerHomeCubit(_profileRepository)..getProfile(),
                child: child,
              ),
          routes: [
            GoRoute(
              path: RouteNames.passengerHome,
              builder: (BuildContext context, GoRouterState state) {
                return const PassengerHomeView();
              },
            ),
            GoRoute(
              path: RouteNames.passengerProfileEdit,
              builder: (context, state) {
                return BlocProvider<PassengerProfileEditCubit>(
                  create: (_) =>
                      PassengerProfileEditCubit(_profileRepository)
                        ..getProfile(),
                  child: const PassengerProfileEditView(),
                );
              },
            ),
          ]),
      GoRoute(
        path: RouteNames.driverProfile,
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<DriverProfileCubit>(
            create: (_) => DriverProfileCubit(_repository),
            child: const DriverRegistrationView(),
          );
        },
      ),
      GoRoute(
        path: RouteNames.driverPendingReview,
        builder: (BuildContext context, GoRouterState state) {
          return const DriverPendingReviewView();
        },
      ),
      GoRoute(
        path: RouteNames.driverRejection,
        builder: (BuildContext context, GoRouterState state) {
          final reason = state.extra is String ? state.extra as String : '';
          return DriverRejectionView(rejectionReason: reason);
        },
      ),
    ],
  );
}
