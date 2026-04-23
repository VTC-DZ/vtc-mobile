// lib/features/auth/presentation/views/passenger_profile_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../cubit/passenger_profile_cubit/passenger_profile_cubit.dart';
import '../cubit/passenger_profile_cubit/passenger_profile_state.dart';
import 'widgets/profile/passenger_profile_form_section.dart';
import 'widgets/profile/profile_step_progress_bar_widget.dart';

/// Step 5 — Passenger Profile Setup.
///
/// Collects Full Name (required, validated), Gender (required, toggle),
/// and Email (optional). On success navigates to the Passenger Home screen.
class PassengerProfileView extends StatelessWidget {
  const PassengerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PassengerProfileCubit, PassengerProfileState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ProfileStatus.success,
      listener: (context, state) {
        if (state.status == ProfileStatus.success) {
          context.go(RouteNames.passengerHome);
        }
      },
      child: AppScaffold(
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 32.h),
                      const ProfileStepProgressBarWidget(
                        currentStep: 2,
                        totalSteps: 3,
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        'Complete your\nprofile',
                        style: AppTextStyles.displayMedium(context),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Just a few quick details to get you started',
                        style: AppTextStyles.bodyMedium(context),
                      ),
                      SizedBox(height: 40.h),
                      const PassengerProfileFormSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
