import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/app_text_field.dart';

class ProfileEmailFieldWidget extends StatelessWidget {
  const ProfileEmailFieldWidget({
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
      controller: controller,
      hintText: 'your@email.com (optional)',
      prefixIcon: const Icon(Icons.mail_outline_rounded),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      error: error,
      enabled: enabled,
    );
  }
}
