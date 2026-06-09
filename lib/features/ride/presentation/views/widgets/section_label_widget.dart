import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';

class SectionLabelWidget extends StatelessWidget {
  const SectionLabelWidget({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelMedium(context).copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
