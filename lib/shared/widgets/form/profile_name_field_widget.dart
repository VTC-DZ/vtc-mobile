import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_text_field.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/validation_patterns.dart';

class ProfileNameFieldWidget extends StatelessWidget {
  const ProfileNameFieldWidget({
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
    return AppTextField(
      unfocusOnTapOutside: false,
      controller: controller,
      hintText: AppStrings.hintFullName,
      prefixIcon: const Icon(Icons.person_outline_rounded),
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [
        FilteringTextInputFormatter.allow(ValidationPatterns.nameInputChars),
      ],
      onChanged: onChanged,
      error: error,
      enabled: enabled,
    );
  }
}
