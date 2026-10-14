import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../../shared/widgets/app_scaffold.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/form/profile_error_banner_widget.dart';
import '../widgets/profile/driver/profile_step_progress_bar_widget.dart';
import '../../cubit/driver_registration_cubit/driver_registration_cubit.dart';
import '../../cubit/driver_registration_cubit/driver_registration_state.dart';
import '../widgets/profile/driver/steps/driver_step1_personal_info.dart';
import '../widgets/profile/driver/steps/driver_step2_vehicle_info.dart';
import '../widgets/profile/driver/steps/driver_step3_documents.dart';

class DriverRegistrationView extends StatelessWidget {
  const DriverRegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverRegistrationCubit, DriverRegistrationState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status &&
          curr.status == DriverRegistrationStatus.success,
      listener: (context, state) => context.go(RouteNames.driverStatusReview),
      builder: (context, state) {
        final cubit = context.read<DriverRegistrationCubit>();

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _goBack(context);
          },
          child: AppScaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 32.h),
                  ProfileStepProgressBarWidget(
                    currentStep: state.currentStep.index + 1,
                    totalSteps: DriverStep.values.length,
                    stepLabels: [
                      for (final step in DriverStep.values) step.label
                    ],
                    completedSteps: {
                      if (state.canProceedStep1) 2,
                      if (state.canProceedStep1 && state.canProceedStep2) 3,
                    },
                    onStepTap: cubit.goToStep,
                  ),
                  SizedBox(height: 20.h),
                  const Expanded(
                    child: SingleChildScrollView(
                        physics: ClampingScrollPhysics(),
                        child: _StepContent()),
                  ),
                  _ErrorBanner(message: state.errorMessage),
                  if (state.status == DriverRegistrationStatus.loading &&
                      state.currentStep == DriverStep.documents)
                    _SubmitProgress(percent: state.submitPercent),
                ],
              ),
            ),
            bottomNavigationBar: _ActionButton(cubit: cubit, state: state),
          ),
        );
      },
    );
  }

  /// System back steps back through the wizard. On step 1 it leaves, after
  /// asking when that would lose what the user entered.
  Future<void> _goBack(BuildContext context) async {
    final cubit = context.read<DriverRegistrationCubit>();
    final state = cubit.state;
    if (state.status == DriverRegistrationStatus.loading) return;
    if (state.currentStep != DriverStep.personalInfo) {
      cubit.goBackStep();
      return;
    }
    if (cubit.hasChanges) {
      final leave = await showAppConfirmDialog(
        context: context,
        title: AppStrings.leaveApplicationTitle,
        message: AppStrings.leaveApplicationBody,
        confirmLabel: AppStrings.leaveApplication,
        cancelLabel: AppStrings.stayOnApplication,
        isDestructive: true,
      );
      if (leave != true || !context.mounted) return;
    }
    // A re-submission opens the wizard with `go`, so nothing sits below it.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.driverStatusReview);
    }
  }
}

// ── Private components ────────────────────────────────────────────────────────

class _StepContent extends StatelessWidget {
  const _StepContent();

  @override
  Widget build(BuildContext context) {
    final currentStep =
        context.select((DriverRegistrationCubit c) => c.state.currentStep);
    return IndexedStack(
      index: currentStep.index,
      children: const [
        DriverStep1PersonalInfo(),
        DriverStep2VehicleInfo(),
        DriverStep3Documents(),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: message.isNotEmpty
          ? Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: ProfileErrorBannerWidget(message: message),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// The real upload of the application. Indeterminate while the photos are
/// still being compressed, before the first byte is sent.
class _SubmitProgress extends StatelessWidget {
  const _SubmitProgress({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: percent == 0 ? null : percent / 100,
              minHeight: 6.h,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.uploadingDocuments(percent),
            style: AppTextStyles.labelSmall(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.cubit, required this.state});
  final DriverRegistrationCubit cubit;
  final DriverRegistrationState state;

  String get _label => switch (state.currentStep) {
        DriverStep.documents => AppStrings.submitApplication,
        DriverStep.personalInfo ||
        DriverStep.vehicleInfo =>
          AppStrings.continueLabel,
      };

  VoidCallback get _action => switch (state.currentStep) {
        DriverStep.personalInfo => cubit.submitStep1,
        DriverStep.vehicleInfo => cubit.proceedStep2,
        DriverStep.documents => cubit.submitStep3,
      };

  bool get _enabled => switch (state.currentStep) {
        DriverStep.personalInfo => state.canProceedStep1,
        DriverStep.vehicleInfo => state.canProceedStep2,
        DriverStep.documents => state.canSubmitStep3,
      };

  // Step 1 loads while it saves the account, step 3 while it submits.
  bool get _loading => state.status == DriverRegistrationStatus.loading;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: _label,
      isEnabled: _enabled,
      isLoading: _loading,
      onPressed: _action,
    );
  }
}
