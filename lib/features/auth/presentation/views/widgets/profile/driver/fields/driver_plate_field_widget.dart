import 'package:flutter/material.dart';

import '../../../../../../../../core/utils/algerian_plate.dart';
import 'driver_text_field_widget.dart';
import '../../../../../../../../core/constants/app_strings.dart';

class DriverPlateFieldWidget extends StatelessWidget {
  const DriverPlateFieldWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.error,
    required this.enabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DriverTextFieldWidget(
      controller: controller,
      hintText: AppStrings.hintPlate,
      icon: Icons.pin_outlined,
      onChanged: onChanged,
      error: error,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.none,
      inputFormatters: [AlgerianPlateFormatter()],
    );
  }
}
