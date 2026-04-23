import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../shared/widgets/app_text_field.dart';

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
      controller: controller,
      hintText: 'e.g. Youcef Benali',
      prefixIcon: const Icon(Icons.person_outline_rounded),
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZÀ-ÿ '\-]")),
      ],
      onChanged: onChanged,
      error: error,
      enabled: enabled,
    );
  }
}
