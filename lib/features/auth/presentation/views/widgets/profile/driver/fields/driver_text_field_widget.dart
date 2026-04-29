import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../../shared/widgets/app_text_field.dart';

class DriverTextFieldWidget extends StatelessWidget {
  const DriverTextFieldWidget({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.onChanged,
    required this.error,
    required this.enabled,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.words,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final String error;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      unfocusOnTapOutside: false,
      controller: controller,
      hintText: hintText,
      prefixIcon: Icon(icon),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      error: error,
      enabled: enabled,
    );
  }
}
