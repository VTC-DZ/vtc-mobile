import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/top_bar.dart';

class DriverHomeView extends StatelessWidget {
  const DriverHomeView({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}
