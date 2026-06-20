import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../ride/shared/models/shared_ride_models.dart';
import '../../cubit/driver_service_types_cubit/driver_service_types_cubit.dart';
import '../../cubit/driver_service_types_cubit/driver_service_types_state.dart';

class DriverServiceTypesWidget extends StatelessWidget {
  const DriverServiceTypesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Listener-only (no builder): surfaces errors without rebuilding the rows.
    return BlocListener<DriverServiceTypesCubit, DriverServiceTypesState>(
      listenWhen: (prev, curr) =>
          curr.status == DriverServiceTypesStatus.failed &&
          curr.errorMessage.isNotEmpty,
      listener: (context, state) => AppToast.error(state.errorMessage),
      child: Column(
        children: [
          for (final type in ServiceType.values) ...[
            _ServiceTypeRow(type: type),
            if (type != ServiceType.values.last) SizedBox(height: 12.h),
          ],
        ],
      ),
    );
  }
}

class _ServiceTypeRow extends StatelessWidget {
  const _ServiceTypeRow({required this.type});

  final ServiceType type;

  @override
  Widget build(BuildContext context) {
    // Each row watches only its own slice, so toggling one type does not
    // rebuild the other row.
    final isEnabled = context.select<DriverServiceTypesCubit, bool>(
      (cubit) => cubit.state.isEnabled(type),
    );
    final isPending = context.select<DriverServiceTypesCubit, bool>(
      (cubit) => cubit.state.isPending(type),
    );

    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderDefault(context),
          width: 1.5.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            type.icon,
            size: 20.w,
            color: isEnabled
                ? AppColors.primary
                : AppColors.textSecondary(context),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              type.label,
              style: AppTextStyles.inputText(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          isPending
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Switch(
                  value: isEnabled,
                  onChanged: (value) => context
                      .read<DriverServiceTypesCubit>()
                      .toggle(type, value),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                ),
        ],
      ),
    );
  }
}
