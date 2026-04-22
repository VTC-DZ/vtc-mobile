import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/route_names.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../shared/widgets/primary_button.dart';

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
        _ModeCard(
          title: 'Passenger',
          description: 'Book rides and travel comfortably',
          icon: Icons.person_outline_rounded,
          isSelected: _selectedMode == UserMode.passenger,
          onTap: () => setState(() => _selectedMode = UserMode.passenger),
        ),
        SizedBox(height: 20.h),
        _ModeCard(
          title: 'Driver',
          description: 'Drive, earn, and be your own boss',
          icon: Icons.directions_car_outlined,
          isSelected: _selectedMode == UserMode.driver,
          onTap: () => setState(() => _selectedMode = UserMode.driver),
        ),
        SizedBox(height: 24.h),
        PrimaryButton(
          label: 'Continue',
          isEnabled: _selectedMode != null,
          onPressed: _handleContinue,
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? AppColors.primary : AppColors.borderDefault(context);
    final backgroundColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.1)
        : AppColors.surface(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 136.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: borderColor,
            width: 1.5.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.background(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.text(context),
                size: 28.w,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingMedium(context).copyWith(
                      color: AppColors.text(context),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
