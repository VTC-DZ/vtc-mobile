import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/top_bar.dart';
import 'widgets/driver_availability_toggle_widget.dart';

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
            DriverAvailabilityToggleWidget(compact: false),
          ],
        ),
      ),
    );
  }
}
