import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_slim_app_bar.dart';
import '../../data/auth_repository.dart';
import 'widgets/mode/mode_selection_options_section.dart';
import '../../../../core/constants/app_strings.dart';

/// Step 3 & 4 — Mode Selection
///
/// Newly registered users choose their path here.
class ModeSelectionView extends StatelessWidget {
  const ModeSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppSlimAppBar(
        leadingIcon: Icons.logout,
        onLeadingTap: () => _confirmLogout(context),
      ),
      showAppBar: true,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 60.h),
            Text(
              AppStrings.modeTitle,
              style: AppTextStyles.displayMedium(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              AppStrings.modeSubtitle,
              style: AppTextStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48.h),
            const ModeSelectionOptionsSection(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: AppStrings.logout,
      message: AppStrings.logoutConfirm,
      confirmLabel: AppStrings.logout,
      isDestructive: true,
    );
    if (confirmed == true) {
      if (context.mounted) {
        const AuthRepository().logout();
      }
    }
  }
}
