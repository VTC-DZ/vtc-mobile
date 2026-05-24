import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_scaffold.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../features/auth/presentation/views/widgets/otp/change_number_bar_widget.dart';
import '../../../../../features/auth/presentation/views/widgets/otp/otp_blocked_banner_widget.dart';
import '../../../../../features/auth/presentation/views/widgets/otp/otp_error_row_widget.dart';
import '../../../../../features/auth/presentation/views/widgets/profile/profile_field_label_widget.dart';
import '../cubit/phone_edit_cubit.dart';
import '../cubit/phone_edit_state.dart';

class PhoneEditView extends StatelessWidget {
  const PhoneEditView({super.key, required this.onSuccess});

  final void Function(String phone) onSuccess;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PhoneEditCubit>();

    return BlocListener<PhoneEditCubit, PhoneEditState>(
      listenWhen: (prev, curr) => curr.status == PhoneEditStatus.success,
      listener: (context, state) {
        AppToast.success('Phone updated successfully');
        onSuccess(state.newPhone);
        context.pop();
      },
      child: AppScaffold(
        showAppBar: true,
        appBarTitle: 'Change Phone',
        onLeadingTap: () => context.pop(),
        body: BlocBuilder<PhoneEditCubit, PhoneEditState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: state.step == PhoneEditStep.phoneEntry
                  ? _PhoneEntrySection(cubit: cubit, state: state)
                  : _OtpVerificationSection(cubit: cubit, state: state),
            );
          },
        ),
      ),
    );
  }
}

class _PhoneEntrySection extends StatelessWidget {
  const _PhoneEntrySection({required this.cubit, required this.state});

  final PhoneEditCubit cubit;
  final PhoneEditState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40.h),
            const ProfileFieldLabelWidget(label: 'New Phone Number'),
            SizedBox(height: 8.h),
            AppTextField(
              controller: cubit.phoneController,
              hintText: AppConstants.phoneHint,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(AppConstants.phoneMaxLength),
              ],
              onChanged: cubit.phoneChanged,
              error: state.phoneError,
              enabled: state.status != PhoneEditStatus.loading,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: state.errorMessage.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(top: 16.h),
                      child: _ErrorBanner(message: state.errorMessage),
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(height: 24.h),
            PrimaryButton(
              label: 'Send Code',
              isEnabled: state.canRequestOtp,
              isLoading: state.status == PhoneEditStatus.loading,
              onPressed: cubit.requestPhoneChange,
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

class _OtpVerificationSection extends StatefulWidget {
  const _OtpVerificationSection({required this.cubit, required this.state});

  final PhoneEditCubit cubit;
  final PhoneEditState state;

  @override
  State<_OtpVerificationSection> createState() =>
      _OtpVerificationSectionState();
}

class _OtpVerificationSectionState extends State<_OtpVerificationSection> {
  static const int _digitCount = 6;
  late final TextEditingController _otpController;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _syncValue(String value) {
    if (_otpController.text != value) {
      _otpController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    final isComplete = value.length == _digitCount;
    if (isComplete != _isComplete) {
      setState(() => _isComplete = isComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = widget.cubit;

    final defaultTheme = PinTheme(
      width: 46.w,
      height: 56.h,
      textStyle: AppTextStyles.displaySmall(context).copyWith(
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderDefault(context),
          width: 1.5.w,
        ),
      ),
    );

    return BlocListener<PhoneEditCubit, PhoneEditState>(
      listenWhen: (prev, curr) =>
          prev.otpValue != curr.otpValue || prev.status != curr.status,
      listener: (context, state) => _syncValue(state.otpValue),
      child: BlocBuilder<PhoneEditCubit, PhoneEditState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.errorMessage != curr.errorMessage ||
            prev.secondsRemaining != curr.secondsRemaining ||
            prev.resendCount != curr.resendCount ||
            prev.blockSecondsRemaining != curr.blockSecondsRemaining,
        builder: (context, state) {
          final isBlocked = state.status == PhoneEditStatus.blocked;
          final isLoading = state.status == PhoneEditStatus.loading;
          final hasWrongCode = state.status == PhoneEditStatus.failure;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                Text(
                  'Verify your number',
                  style: AppTextStyles.headingSmall(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Enter the code sent to ****${state.lastFourDigits}',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                if (isBlocked)
                  OtpBlockedBannerWidget(seconds: state.blockSecondsRemaining)
                else ...[
                  Pinput(
                    controller: _otpController,
                    length: _digitCount,
                    autofocus: true,
                    enabled: !isLoading,
                    forceErrorState: hasWrongCode,
                    hapticFeedbackType: HapticFeedbackType.lightImpact,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    defaultPinTheme: defaultTheme,
                    focusedPinTheme: defaultTheme.copyWith(
                      decoration: defaultTheme.decoration!.copyWith(
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    submittedPinTheme: defaultTheme.copyWith(
                      decoration: defaultTheme.decoration!.copyWith(
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1.5.w,
                        ),
                      ),
                    ),
                    errorPinTheme: defaultTheme.copyWith(
                      decoration: defaultTheme.decoration!.copyWith(
                        border: Border.all(
                          color: AppColors.error,
                          width: 1.5.w,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      cubit.otpChanged(value);
                      setState(() => _isComplete = value.length == _digitCount);
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    child: hasWrongCode && state.errorMessage.isNotEmpty
                        ? Padding(
                            padding: EdgeInsets.only(top: 12.h),
                            child: OtpErrorRowWidget(message: state.errorMessage),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
                SizedBox(height: 36.h),
                if (!isBlocked)
                  PrimaryButton(
                    label: 'Verify',
                    isEnabled: _isComplete && !isLoading,
                    isLoading: isLoading,
                    onPressed: cubit.confirmPhoneChange,
                  ),
                SizedBox(height: 28.h),
                if (!isBlocked) _ResendRow(state: state, onResend: _onResend),
                SizedBox(height: 16.h),
                ChangeNumberBarWidget(onTap: cubit.goBackToPhoneEntry),
                SizedBox(height: 24.h),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onResend() {
    _otpController.clear();
    setState(() => _isComplete = false);
    widget.cubit.resendOtp();
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.state, required this.onResend});

  final PhoneEditState state;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final waiting = state.secondsRemaining > 0;
    final exhausted = state.resendCount >= AppConstants.otpMaxResendCount;

    return Column(
      children: [
        if (waiting)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined,
                  size: 15.sp, color: AppColors.textSecondary(context)),
              SizedBox(width: 6.w),
              Text(
                'Resend code in ${_timerLabel()}',
                style: AppTextStyles.bodySmall(context),
              ),
            ],
          ),
        if (!waiting && !exhausted)
          GestureDetector(
            onTap: onResend,
            child: Text(
              'Resend Code',
              style: AppTextStyles.labelMedium(context).copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        if (!waiting && exhausted)
          Text(
            'Maximum resend attempts reached',
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.error,
            ),
          ),
        if (state.resendCount > 0 && !exhausted)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              '${AppConstants.otpMaxResendCount - state.resendCount} resend${AppConstants.otpMaxResendCount - state.resendCount == 1 ? '' : 's'} remaining',
              style: AppTextStyles.labelSmall(context),
            ),
          ),
      ],
    );
  }

  String _timerLabel() {
    final m = state.secondsRemaining ~/ 60;
    final s = state.secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              size: 18.sp, color: AppColors.error),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
