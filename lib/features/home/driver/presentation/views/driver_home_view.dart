import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class DriverHomeView extends StatelessWidget {
  const DriverHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: const SafeArea(
        child: Center(
          child: Text('Driver Home'),
        ),
      ),
    );
  }
}
