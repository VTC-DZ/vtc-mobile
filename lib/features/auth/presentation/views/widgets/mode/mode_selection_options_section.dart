import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/route_names.dart';
import '../../../../../../shared/widgets/primary_button.dart';
import 'mode_card_widget.dart';
import '../../../../../../core/constants/app_strings.dart';

enum UserMode { passenger, driver }

class ModeSelectionOptionsSection extends StatefulWidget {
  const ModeSelectionOptionsSection({super.key});

  @override
  State<ModeSelectionOptionsSection> createState() =>
      _ModeSelectionOptionsSectionState();
}

class _ModeSelectionOptionsSectionState
    extends State<ModeSelectionOptionsSection> {
  UserMode? _selectedMode;

  void _handleContinue() {
    if (_selectedMode == UserMode.passenger) {
      context.push(RouteNames.passengerProfile);
    } else if (_selectedMode == UserMode.driver) {
      context.push(RouteNames.driverProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModeCard(
          title: AppStrings.modePassenger,
          description: AppStrings.modePassengerBody,
          icon: Icons.person_outline_rounded,
          isSelected: _selectedMode == UserMode.passenger,
          onTap: () => setState(() => _selectedMode = UserMode.passenger),
        ),
        SizedBox(height: 20.h),
        ModeCard(
          title: AppStrings.modeDriver,
          description: AppStrings.modeDriverBody,
          icon: Icons.directions_car_outlined,
          isSelected: _selectedMode == UserMode.driver,
          onTap: () => setState(() => _selectedMode = UserMode.driver),
        ),
        SizedBox(height: 24.h),
        PrimaryButton(
          label: AppStrings.continueLabel,
          isEnabled: _selectedMode != null,
          onPressed: _handleContinue,
        ),
      ],
    );
  }
}
