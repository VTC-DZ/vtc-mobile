import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rapidoo/core/helper/observer.dart';
import 'package:rapidoo/firebase_options.dart';

import 'core/constants/app_constants.dart';
import 'core/network/dio_client.dart';
import 'core/push/push_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/session/auth_session.dart';
import 'core/storage/secure_storage_helper.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Bloc.observer = MyBlocObserver();
  SecureStorageHelper.init();
  // SecureStorageHelper.removeAllSecureStorage();
  await AuthSession.loadSession();
  DioClient.init();
  await PushNotificationService.init();
  runApp(const MyApp());
  unawaited(PushNotificationService.handleLaunchTap());
  if (AuthSession.isLoggedIn) {
    unawaited(PushNotificationService.registerDevice());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(
        AppConstants.designWidth,
        AppConstants.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
