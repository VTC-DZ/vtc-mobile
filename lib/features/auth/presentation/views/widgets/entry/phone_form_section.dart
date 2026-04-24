import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../shared/widgets/app_text_field.dart';
import '../../../../../../shared/widgets/primary_button.dart';
import '../../../cubit/phone_cubit/phone_cubit.dart';
import '../../../cubit/phone_cubit/phone_state.dart';

class PhoneFormSection extends StatefulWidget {
  const PhoneFormSection({super.key});

  @override
  State<PhoneFormSection> createState() => _PhoneFormSectionState();
}

class _PhoneFormSectionState extends State<PhoneFormSection> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhoneCubit, PhoneState>(
      builder: (context, state) {
        return Column(
          children: [
            AppTextField(
              controller: _phoneController,
              hintText: AppConstants.phoneHint,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(AppConstants.phoneMaxLength),
              ],
              onChanged: context.read<PhoneCubit>().phoneChanged,
              error: state.errorMessage,
            ),
            SizedBox(height: 24.h),
            PrimaryButton(
              label: 'Continue',
              isEnabled: state.isValid,
              isLoading: state.status == PhoneStatus.loading,
              onPressed: context.read<PhoneCubit>().sendOtp,
            ),
          ],
        );
      },
    );
  }
}
