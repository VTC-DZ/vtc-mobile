import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';

class ProfileStepProgressBarWidget extends StatelessWidget {
  const ProfileStepProgressBarWidget({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final filled = index < currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4.w : 0),
            height: 4.h,
            decoration: BoxDecoration(
              color:
                  filled ? AppColors.primary : AppColors.borderDefault(context),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        );
      }),
    );
  }
}
