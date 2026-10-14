import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../cubit/otp_cubit/otp_cubit.dart';
import '../cubit/otp_cubit/otp_state.dart';
import 'widgets/otp/otp_verification_form_section.dart';
import '../../../../core/constants/app_strings.dart';

/// Step 2 — OTP Verification screen.
///
/// Receives the phone number via GoRouter's [extra] field and displays
/// the last 4 digits in a confirmation label.
class OtpVerificationView extends StatelessWidget {
  const OtpVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final lastFourDigits = context.read<OtpCubit>().state.lastFourDigits;

    return BlocListener<OtpCubit, OtpState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == OtpStatus.success,
      listener: (context, state) {
        if (state.status == OtpStatus.success) {
          if (state.isNewUser) {
            context.go(RouteNames.modeSelection);
          } else {
            context.go(RouteNames.passengerHome);
          }
        }
      },
      child: AppScaffold(
        showAppBar: true,
        appBarTitle: AppStrings.otpAppBarTitle,
        onLeadingTap: () => context.go(RouteNames.phone),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 72.h),
              Text(
                AppStrings.otpTitle,
                style: AppTextStyles.displayMedium(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodyMedium(context),
                  children: [
                    const TextSpan(text: AppStrings.otpCodeSentTo),
                    TextSpan(
                      text: '••••$lastFourDigits',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text(context),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
              OtpVerificationFormSection(
                onChangeNumber: () => context.go(RouteNames.phone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
