import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../cubit/phone_cubit/phone_cubit.dart';
import '../cubit/phone_cubit/phone_state.dart';
import 'widgets/entry/phone_form_section.dart';
import '../../../../core/constants/app_strings.dart';

class PhoneEntryView extends StatelessWidget {
  const PhoneEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PhoneCubit, PhoneState>(
      listener: (BuildContext context, PhoneState state) {
        switch (state.status) {
          case PhoneStatus.success:
            context.go(RouteNames.otp, extra: state.phoneE164);
          case PhoneStatus.failure:
          case PhoneStatus.initial:
          case PhoneStatus.loading:
            break;
        }
      },
      child: AppScaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 80.h),
              Text(
                AppStrings.phoneTitle,
                style: AppTextStyles.displayMedium(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                AppStrings.phoneSubtitle,
                style: AppTextStyles.bodyMedium(context),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              const PhoneFormSection(),
              Text(
                AppStrings.phoneTerms,
                style: AppTextStyles.labelSmall(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
