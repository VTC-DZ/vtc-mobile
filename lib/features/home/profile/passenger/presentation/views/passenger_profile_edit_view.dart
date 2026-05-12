import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:khfif_drif/features/home/passenger/presentation/cubit/passenger_home_cubit.dart';
import 'package:khfif_drif/features/home/passenger/presentation/cubit/passenger_home_state.dart';
import 'package:khfif_drif/features/home/passenger/presentation/views/widgets/top_bar.dart';

import '../../../../../../core/router/route_names.dart';
import '../../../../../../core/widgets/app_toast.dart';
import 'widgets/profile_edit_shimmer_widget.dart';
import 'widgets/profile_email_edit_row_widget.dart';
import '../../../../../../features/auth/presentation/views/widgets/profile/driver/fields/driver_date_picker_field_widget.dart';
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
      listenWhen: (prev, curr) =>
          curr.updateProfileStatus == UpdateProfileStatus.success,
      listener: (context, state) {
        AppToast.success('Profile updated successfully');
        context.read<PassengerHomeCubit>().updateProfile(state.savedProfile!);
        context.read<PassengerHomeCubit>().updateSelectedIndex(0);
        context.go(RouteNames.passengerHome);
      },
      child: AppScaffold(
        bottomNavigationBar:
            BlocBuilder<PassengerProfileEditCubit, PassengerProfileEditState>(
          buildWhen: (prev, curr) =>
              prev.canSave != curr.canSave ||
              prev.updateProfileStatus != curr.updateProfileStatus,
          builder: (context, state) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: PrimaryButton(
              label: 'Save Changes',
              isEnabled: state.canSave,
              isLoading:
                  state.updateProfileStatus == UpdateProfileStatus.loading,
              onPressed: cubit.updateProfile,
            ),
          ),
        ),
        body: Column(
          children: [
            const TopBar(
              title: 'Edit Profile',
              subtitle: 'Profile',
              leadingIcon: Icons.menu_rounded,
              trailingIcon: null,
            ),
            Expanded(
              child: BlocBuilder<PassengerHomeCubit, PassengerHomeState>(
                buildWhen: (previous, current) {
                  return (previous.status != current.status ||
                      previous.profile != current.profile);
                },
                builder: (context, state) {
                  if (state.status == PassengerHomeStatus.loading) {
                    return const ProfileEditShimmerWidget();
                  } else if (state.status == PassengerHomeStatus.success) {
                    context
                        .read<PassengerProfileEditCubit>()
                        .initData(state.profile!);
                  }
                  return BlocBuilder<PassengerProfileEditCubit,
                      PassengerProfileEditState>(
                    buildWhen: (prev, curr) =>
                        prev.updateProfileStatus != curr.updateProfileStatus ||
                        prev.gender != curr.gender ||
                        prev.dateOfBirth != curr.dateOfBirth ||
                        prev.nameError != curr.nameError ||
                        prev.errorMessage != curr.errorMessage,
                    builder: (context, state) {
                      return SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 24.h),
                              const ProfileFieldLabelWidget(label: 'Full Name'),
                              SizedBox(height: 8.h),
                              ProfileNameFieldWidget(
                                controller: cubit.nameController,
                                onChanged: cubit.nameChanged,
                                error: state.nameError,
                                enabled: state.updateProfileStatus !=
                                    UpdateProfileStatus.loading,
                              ),
                              SizedBox(height: 24.h),
                              const ProfileFieldLabelWidget(label: 'Gender'),
                              SizedBox(height: 8.h),
                              ProfileGenderToggleWidget(
                                selected: state.gender,
                                onChanged: cubit.genderChanged,
                                enabled: state.updateProfileStatus !=
                                    UpdateProfileStatus.loading,
                              ),
                              SizedBox(height: 24.h),
                              const ProfileFieldLabelWidget(
                                  label: 'Date of Birth'),
                              SizedBox(height: 8.h),
                              DriverDatePickerFieldWidget(
                                selectedDate: state.dateOfBirth,
                                onDateSelected: cubit.dateOfBirthChanged,
                                enabled: state.updateProfileStatus !=
                                    UpdateProfileStatus.loading,
                              ),
                              SizedBox(height: 24.h),
                              const ProfileFieldLabelWidget(
                                label: 'Email',
                                badge: 'Optional',
                              ),
                              SizedBox(height: 8.h),
                              BlocBuilder<PassengerProfileEditCubit,
                                  PassengerProfileEditState>(
                                buildWhen: (prev, curr) =>
                                    prev.email != curr.email,
                                builder: (context, state) =>
                                    ProfileEmailEditRowWidget(
                                  email: state.email,
                                  onTap: () => context.push(
                                    RouteNames.passengerEmailEdit,
                                    extra: state.email ?? '',
                                  ),
                                ),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
