import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_scaffold.dart';
import '../../cubit/passenger_profile_cubit/passenger_profile_cubit.dart';
import '../../cubit/passenger_profile_cubit/passenger_profile_state.dart';
import '../widgets/profile/passenger/passenger_profile_form_section.dart';
import '../../../../../core/constants/app_strings.dart';

/// Step 5 — Passenger Profile Setup.
///
/// Collects full name, gender and date of birth, all required. On success
/// navigates to the Passenger Home screen.
class PassengerProfileView extends StatefulWidget {
  const PassengerProfileView({super.key});

  @override
  State<PassengerProfileView> createState() => _PassengerProfileViewState();
}

class _PassengerProfileViewState extends State<PassengerProfileView> {
  late final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PassengerProfileCubit, PassengerProfileState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == ProfileStatus.success,
        listener: (context, state) => context.go(RouteNames.passengerHome),
        child: AppScaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 32.h),
                  Text(
                    AppStrings.profileSetupTitle,
                    style: AppTextStyles.displayMedium(context),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    AppStrings.profileSetupSubtitle,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                  SizedBox(height: 40.h),
                  PassengerProfileFormSection(nameController: _nameController),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: BlocBuilder<PassengerProfileCubit, PassengerProfileState>(
              buildWhen: (previous, current) =>
                  previous.canSubmit != current.canSubmit ||
                  previous.status != current.status,
              builder: (context, state) {
                final isLoading = state.status == ProfileStatus.loading;

                return PrimaryButton(
                  label: AppStrings.continueLabel,
                  isEnabled: state.canSubmit,
                  isLoading: isLoading,
                  onPressed: context.read<PassengerProfileCubit>().submit,
                );
              },
            ),
          ),
        ));
  }
}
