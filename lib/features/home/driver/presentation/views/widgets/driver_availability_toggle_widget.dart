import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../features/ride/driver/presentation/cubit/driver_availability_cubit/driver_availability_cubit.dart';
import '../../../../../../features/ride/driver/presentation/cubit/driver_availability_cubit/driver_availability_state.dart';

class DriverAvailabilityToggleWidget extends StatelessWidget {
  const DriverAvailabilityToggleWidget({
    super.key,
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverAvailabilityCubit, DriverAvailabilityState>(
      builder: (context, state) {
        final isOnline = state.isOnline;
        final isLoading = state.status == DriverAvailabilityStatus.loading;

        if (compact) {
          return _CompactToggle(
            isOnline: isOnline,
            isLoading: isLoading,
            onChanged: (_) => context.read<DriverAvailabilityCubit>().toggle(),
          );
        }

        return _FullToggle(
          isOnline: isOnline,
          isLoading: isLoading,
          onChanged: (_) => context.read<DriverAvailabilityCubit>().toggle(),
        );
      },
    );
  }
}

class _FullToggle extends StatelessWidget {
  const _FullToggle({
    required this.isOnline,
    required this.isLoading,
    required this.onChanged,
  });

  final bool isOnline;
  final bool isLoading;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surface(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isOnline
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.borderDefault(context),
          width: 1.5.w,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: isOnline
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.borderDefault(context).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                key: ValueKey(isOnline),
                size: 18.w,
                color: isOnline
                    ? AppColors.primary
                    : AppColors.textSecondary(context),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    isOnline
                        ? 'Visible to passengers'
                        : 'Not receiving requests',
                    key: ValueKey('sub_$isOnline'),
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          isLoading
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Switch(
                  value: isOnline,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                ),
        ],
      ),
    );
  }
}

class _CompactToggle extends StatelessWidget {
  const _CompactToggle({
    required this.isOnline,
    required this.isLoading,
    required this.onChanged,
  });

  final bool isOnline;
  final bool isLoading;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
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
                onChanged: onChanged,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              ),
      ],
    );
  }
}
