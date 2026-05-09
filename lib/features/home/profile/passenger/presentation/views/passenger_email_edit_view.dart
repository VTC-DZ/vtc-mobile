import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:khfif_drif/features/home/passenger/presentation/cubit/passenger_home_cubit.dart';

import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../features/auth/presentation/views/widgets/profile/passenger/profile_email_field_widget.dart';
import '../../../../../../features/auth/presentation/views/widgets/profile/passenger/profile_error_banner_widget.dart';
import '../../../../../../features/auth/presentation/views/widgets/profile/profile_field_label_widget.dart';
import '../../../../../../shared/widgets/app_scaffold.dart';
import '../../../../../../shared/widgets/primary_button.dart';
import '../cubit/passenger_email_edit_cubit.dart';
import '../cubit/passenger_email_edit_state.dart';

class PassengerEmailEditView extends StatelessWidget {
  const PassengerEmailEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PassengerEmailEditCubit>();

    return BlocListener<PassengerEmailEditCubit, PassengerEmailEditState>(
      listenWhen: (prev, curr) => curr.status == EmailEditStatus.success,
      listener: (context, state) {
        AppToast.success('Email updated successfully');
        context.read<PassengerHomeCubit>().updateEmail(state.email);
        context.pop();
      },
      child: AppScaffold(
        showAppBar: true,
        appBarTitle: 'Edit Email',
        onLeadingTap: () => context.pop(),
        bottomNavigationBar:
            BlocBuilder<PassengerEmailEditCubit, PassengerEmailEditState>(
          buildWhen: (prev, curr) =>
              prev.canSave != curr.canSave || prev.status != curr.status,
          builder: (context, state) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: PrimaryButton(
              label: 'Save',
              isEnabled: state.canSave,
              isLoading: state.status == EmailEditStatus.saving,
              onPressed: cubit.updateEmail,
            ),
          ),
        ),
        body: BlocBuilder<PassengerEmailEditCubit, PassengerEmailEditState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40.h),
                    const ProfileFieldLabelWidget(label: 'Email'),
                    SizedBox(height: 8.h),
                    ProfileEmailFieldWidget(
                      controller: cubit.emailController,
                      onChanged: cubit.emailChanged,
                      error: state.emailError,
                      enabled: state.status != EmailEditStatus.saving,
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
