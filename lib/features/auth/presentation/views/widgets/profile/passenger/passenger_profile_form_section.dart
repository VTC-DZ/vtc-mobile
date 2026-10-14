import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../cubit/passenger_profile_cubit/passenger_profile_cubit.dart';
import '../../../../cubit/passenger_profile_cubit/passenger_profile_state.dart';
import '../../../../../../../shared/widgets/form/profile_error_banner_widget.dart';
import '../../../../../../../shared/widgets/form/profile_field_label_widget.dart';
import '../../../../../../../shared/widgets/form/profile_gender_toggle_widget.dart';
import '../../../../../../../shared/widgets/form/profile_name_field_widget.dart';
import '../../../../../../../shared/widgets/form/app_date_picker_field_widget.dart';
import '../../../../../../../core/constants/app_strings.dart';

class PassengerProfileFormSection extends StatelessWidget {
  const PassengerProfileFormSection({
    super.key,
    required this.nameController,
  });

  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PassengerProfileCubit>();

    return BlocBuilder<PassengerProfileCubit, PassengerProfileState>(
      buildWhen: (previous, current) =>
          previous.gender != current.gender ||
          previous.dateOfBirth != current.dateOfBirth ||
          previous.nameError != current.nameError ||
          previous.errorMessage != current.errorMessage ||
          previous.status != current.status,
      builder: (context, state) {
        final isSubmitting = state.status == ProfileStatus.loading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProfileFieldLabelWidget(label: AppStrings.fieldFullName),
            SizedBox(height: 8.h),
            ProfileNameFieldWidget(
              controller: nameController,
              onChanged: cubit.nameChanged,
              error: state.nameError,
              enabled: !isSubmitting,
            ),
            SizedBox(height: 24.h),
            const ProfileFieldLabelWidget(label: AppStrings.fieldGender),
            SizedBox(height: 8.h),
            ProfileGenderToggleWidget(
              selected: state.gender,
              onChanged: cubit.genderChanged,
              enabled: !isSubmitting,
            ),
            SizedBox(height: 24.h),
            const ProfileFieldLabelWidget(label: AppStrings.fieldDateOfBirth),
            SizedBox(height: 8.h),
            AppDatePickerFieldWidget(
              selectedDate: state.dateOfBirth,
              onDateSelected: cubit.dateOfBirthChanged,
              enabled: !isSubmitting,
            ),
            SizedBox(height: 8.h),
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: state.errorMessage.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(top: 16.h),
                      child: ProfileErrorBannerWidget(
                        message: state.errorMessage,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
