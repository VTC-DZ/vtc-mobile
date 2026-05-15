// lib/features/auth/presentation/views/driver/driver_pending_review_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_scaffold.dart';
import '../../../../../shared/widgets/primary_button.dart';

/// Shown after the driver successfully submits all documents.
/// Account status is now "Pending Review" — no back navigation allowed.
class DriverPendingReviewView extends StatelessWidget {
  const DriverPendingReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppScaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),

                // ── Lottie Animation ──────────────────────────────────────────
                Lottie.asset(
                  'assets/lottie/loading.json',
                  width: 170.w,
                  height: 170.w,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: 48.h),

                // ── Title ─────────────────────────────────────────────────────
                Text(
                  AppStrings.pendingReviewTitle,
                  style: AppTextStyles.displayMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16.h),

                // ── Body ──────────────────────────────────────────────────────
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

                // ── CTA ───────────────────────────────────────────────────────
                PrimaryButton(
                  label: AppStrings.goToHome,
                  isEnabled: true,
                  onPressed: () => context.go(RouteNames.passengerHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
