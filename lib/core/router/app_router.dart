// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/repo/auth_repository.dart';
import '../../features/auth/presentation/cubit/phone_cubit.dart';
import '../../features/auth/presentation/views/phone_entry_view.dart';
import 'route_names.dart';

/// Builds and owns the app's [GoRouter] instance.
///
/// Receives [AuthRepository] via constructor — no service locator.
final class AppRouter {
  AppRouter({required this.authRepository});

  final AuthRepository authRepository;

  late final GoRouter router = GoRouter(
    initialLocation: RouteNames.phone,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RouteNames.phone,
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<PhoneCubit>(
            create: (_) => PhoneCubit(authRepository),
            child: const PhoneEntryView(),
          );
        },
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (BuildContext context, GoRouterState state) {
          // Placeholder — replaced in Story 2.
          final phone = state.extra as String? ?? '';
          return Scaffold(
            appBar: AppBar(title: const Text('Verify OTP')),
            body: Center(
              child: Text(
                'OTP Page — Story 2\nPhone: $phone',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    ],
  );
}
