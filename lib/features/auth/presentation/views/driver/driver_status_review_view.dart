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
            child: BlocConsumer<KycStatusCubit, KycStatusState>(
              listenWhen: (previous, current) =>
                  !previous.isApproved && current.isApproved,
              listener: (context, state) => context.go(RouteNames.driverHome),
              builder: (context, state) {
                return switch (state.status) {
                  KycStatusViewStatus.initial ||
                  KycStatusViewStatus.loading =>
                    const _LoadingContent(),
                  KycStatusViewStatus.success => _buildContent(context, state),
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
    if (state.isApproved) return const _LoadingContent();
    if (state.isPending || state.isNone) return const _PendingContent();

    // A re-submission starts from the account, which pre-fills step 1; the
    // wizard skips saving it, since a driver profile now exists.
    void resubmit() =>
        context.go(RouteNames.driverProfile, extra: state.profile);

    if (state.isRejected) {
      return _ClosedContent(
        title: AppStrings.rejectionTitle,
        reason: state.kycResult?.resubmissionNote,
        actionLabel: AppStrings.resubmitDocuments,
        onAction: resubmit,
      );
    }
    if (state.isRevoked) {
      // The note belongs to an earlier submission, not to the revocation,
      // and the server exposes no revocation reason, so none is shown.
      return state.canResubmit
          ? _ClosedContent(
              title: AppStrings.revokedTitle,
              message: AppStrings.revokedResubmitBody,
              actionLabel: AppStrings.resubmitDocuments,
              onAction: resubmit,
            )
          : _ClosedContent(
              title: AppStrings.revokedTitle,
              message: AppStrings.revokedNoResubmitBody,
              actionLabel: AppStrings.goToHome,
              onAction: () => context.go(RouteNames.passengerHome),
            );
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
          onPressed: () async {
            if (context.mounted) context.go(RouteNames.passengerHome);
          },
        ),
      ],
    );
  }
}

/// A rejected or revoked application: what happened, and the next step.
class _ClosedContent extends StatelessWidget {
  const _ClosedContent({
    required this.title,
    this.reason,
    this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;

  /// The reviewer's note, shown in the "Reason:" box when there is no
  /// [message].
  final String? reason;

  /// Plain text under the title, in place of the "Reason:" box.
  final String? message;
  final String actionLabel;
  final VoidCallback onAction;

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
          title,
          style: AppTextStyles.displayMedium(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),
        if (message != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              message!,
              style: AppTextStyles.bodyLarge(context).copyWith(
                color: AppColors.textSecondary(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          Text(
            AppStrings.rejectionReasonLabel,
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
              (reason != null && reason!.isNotEmpty)
                  ? reason!
                  : AppStrings.rejectionDefaultReason,
              style: AppTextStyles.bodyMedium(context),
            ),
          ),
        ],
        const Spacer(flex: 3),
        PrimaryButton(
          label: actionLabel,
          isEnabled: true,
          onPressed: onAction,
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
