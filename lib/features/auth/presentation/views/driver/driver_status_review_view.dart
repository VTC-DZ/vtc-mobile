import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_scaffold.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../cubit/kyc_status_cubit/kyc_status_cubit.dart';
import '../../cubit/kyc_status_cubit/kyc_status_state.dart';

class DriverStatusReviewView extends StatelessWidget {
  const DriverStatusReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppScaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: BlocBuilder<KycStatusCubit, KycStatusState>(
              builder: (context, state) {
                return switch (state.status) {
                  KycStatusViewStatus.initial ||
                  KycStatusViewStatus.loading =>
                    const _LoadingContent(),
                  KycStatusViewStatus.success =>
                    _buildContent(context, state),
                  KycStatusViewStatus.failure => _ErrorContent(
                      message: state.errorMessage,
                      onRetry: () =>
                          context.read<KycStatusCubit>().fetchKycStatus(),
                    ),
                };
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, KycStatusState state) {
    if (state.isPending || state.isNone) return const _PendingContent();
    if (state.isApproved) return const _ApprovedContent();
    if (state.isRejected) {
      return _RejectedContent(note: state.kycResult?.resubmissionNote);
    }
    return const _PendingContent();
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 1),
        Center(
          child: SizedBox(
            width: 48.w,
            height: 48.w,
            child: const CircularProgressIndicator(),
          ),
        ),
        SizedBox(height: 32.h),
        Text(
          AppStrings.statusLoadingTitle,
          style: AppTextStyles.displayMedium(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

class _PendingContent extends StatelessWidget {
  const _PendingContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 1),
        Lottie.asset(
          'assets/lottie/loading.json',
          width: 170.w,
          height: 170.w,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 48.h),
        Text(
          AppStrings.pendingReviewTitle,
          style: AppTextStyles.displayMedium(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            AppStrings.pendingReviewBody,
            style: AppTextStyles.bodyLarge(context).copyWith(
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(flex: 3),
        PrimaryButton(
          label: AppStrings.goToHome,
          isEnabled: true,
          onPressed: () => context.go(RouteNames.passengerHome),
        ),
      ],
    );
  }
}

class _ApprovedContent extends StatelessWidget {
  const _ApprovedContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 1),
        Icon(
          Icons.check_circle_rounded,
          size: 72.w,
          color: AppColors.primary,
        ),
        SizedBox(height: 48.h),
        Text(
          AppStrings.statusApprovedTitle,
          style: AppTextStyles.displayMedium(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            AppStrings.statusApprovedBody,
            style: AppTextStyles.bodyLarge(context).copyWith(
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(flex: 3),
        PrimaryButton(
          label: AppStrings.continueLabel,
          isEnabled: true,
          onPressed: () => context.go(RouteNames.passengerHome),
        ),
      ],
    );
  }
}

class _RejectedContent extends StatelessWidget {
  const _RejectedContent({this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 1),
        Icon(
          Icons.cancel_outlined,
          size: 72.w,
          color: AppColors.error,
        ),
        SizedBox(height: 24.h),
        Text(
          AppStrings.rejectionTitle,
          style: AppTextStyles.displayMedium(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),
        Text(
          'Reason:',
          style: AppTextStyles.labelMedium(context)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            (note != null && note!.isNotEmpty)
                ? note!
                : 'Your application did not meet our requirements.',
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
        const Spacer(flex: 3),
        PrimaryButton(
          label: AppStrings.resubmitDocuments,
          isEnabled: true,
          onPressed: () => context.go(RouteNames.driverProfile),
        ),
      ],
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 1),
        Icon(
          Icons.error_outline_rounded,
          size: 72.w,
          color: AppColors.error,
        ),
        SizedBox(height: 32.h),
        Text(
          AppStrings.statusErrorTitle,
          style: AppTextStyles.displayMedium(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            message.isNotEmpty ? message : AppStrings.statusErrorBody,
            style: AppTextStyles.bodyLarge(context).copyWith(
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(flex: 3),
        PrimaryButton(
          label: AppStrings.retry,
          isEnabled: true,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
