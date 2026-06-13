import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../features/ride/driver/presentation/cubit/driver_availability_cubit/driver_availability_cubit.dart';
import '../../../../../../features/ride/driver/presentation/cubit/driver_availability_cubit/driver_availability_state.dart';

class DriverAvailabilityToggleWidget extends StatelessWidget {
  const DriverAvailabilityToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverAvailabilityCubit, DriverAvailabilityState>(
      builder: (context, state) {
        final isOnline = state.isOnline;
        final isLoading = state.status == DriverAvailabilityStatus.loading;

        return Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isOnline ? 'Online' : 'Offline',
                key: ValueKey(isOnline),
                style: AppTextStyles.labelMedium(context).copyWith(
                  color: isOnline
                      ? AppColors.primary
                      : AppColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Switch(
                    value: isOnline,
                    onChanged: (_) =>
                        context.read<DriverAvailabilityCubit>().toggle(),
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
          ],
        );
      },
    );
  }
}
