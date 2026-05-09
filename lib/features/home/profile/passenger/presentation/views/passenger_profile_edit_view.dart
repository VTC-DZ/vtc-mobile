import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:khfif_drif/features/home/passenger/presentation/cubit/passenger_home_cubit.dart';

import '../../../../../../core/widgets/app_toast.dart';
import 'widgets/profile_edit_shimmer_widget.dart';
import '../../../../../../features/auth/presentation/views/widgets/profile/driver/fields/driver_date_picker_field_widget.dart';
import '../../../../../../features/auth/presentation/views/widgets/profile/passenger/profile_email_field_widget.dart';
import '../../../../../../features/auth/presentation/views/widgets/profile/passenger/profile_error_banner_widget.dart';
import '../../../../../../features/auth/presentation/views/widgets/profile/profile_field_label_widget.dart';
import '../../../../../../features/auth/presentation/views/widgets/profile/profile_gender_toggle_widget.dart';
import '../../../../../../features/auth/presentation/views/widgets/profile/profile_name_field_widget.dart';
import '../../../../../../shared/widgets/app_scaffold.dart';
import '../../../../../../shared/widgets/primary_button.dart';
import '../cubit/passenger_profile_edit_cubit.dart';
import '../cubit/passenger_profile_edit_state.dart';

class PassengerProfileEditView extends StatelessWidget {
  const PassengerProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PassengerProfileEditCubit>();

    return BlocListener<PassengerProfileEditCubit, PassengerProfileEditState>(
      listenWhen: (prev, curr) => curr.status == ProfileEditStatus.success,
      listener: (context, state) {
        AppToast.success('Profile updated successfully');
        context.read<PassengerHomeCubit>().getProfile();
        context.pop();
      },
      child: AppScaffold(
        showAppBar: true,
        appBarTitle: 'Edit Profile',
        onLeadingTap: () => context.pop(),
        bottomNavigationBar:
            BlocBuilder<PassengerProfileEditCubit, PassengerProfileEditState>(
          buildWhen: (prev, curr) =>
              prev.canSave != curr.canSave || prev.status != curr.status,
          builder: (context, state) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: PrimaryButton(
              label: 'Save Changes',
              isEnabled: state.canSave,
              isLoading: state.status == ProfileEditStatus.saving,
              onPressed: cubit.updateProfile,
            ),
          ),
        ),
        body: BlocBuilder<PassengerProfileEditCubit, PassengerProfileEditState>(
          buildWhen: (prev, curr) => prev.status != curr.status,
          builder: (context, state) {
            if (state.status == ProfileEditStatus.loading) {
              return const ProfileEditShimmerWidget();
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40.h),
                    const ProfileFieldLabelWidget(label: 'Full Name'),
                    SizedBox(height: 8.h),
                    ProfileNameFieldWidget(
                      controller: cubit.nameController,
                      onChanged: cubit.nameChanged,
                      error: state.nameError,
                      enabled: state.status != ProfileEditStatus.saving,
                    ),
                    SizedBox(height: 24.h),
                    const ProfileFieldLabelWidget(label: 'Gender'),
                    SizedBox(height: 8.h),
                    ProfileGenderToggleWidget(
                      selected: state.gender,
                      onChanged: cubit.genderChanged,
                      enabled: state.status != ProfileEditStatus.saving,
                    ),
                    SizedBox(height: 24.h),
                    const ProfileFieldLabelWidget(label: 'Date of Birth'),
                    SizedBox(height: 8.h),
                    DriverDatePickerFieldWidget(
                      selectedDate: state.dateOfBirth,
                      onDateSelected: cubit.dateOfBirthChanged,
                      enabled: state.status != ProfileEditStatus.saving,
                    ),
                    SizedBox(height: 24.h),
                    const ProfileFieldLabelWidget(
                      label: 'Email',
                      badge: 'Optional',
                    ),
                    SizedBox(height: 8.h),
                    ProfileEmailFieldWidget(
                      controller: cubit.emailController,
                      onChanged: cubit.emailChanged,
                      error: state.emailError,
                      enabled: state.status != ProfileEditStatus.saving,
                    ),
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
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
