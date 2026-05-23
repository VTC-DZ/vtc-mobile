import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddressFormFieldWidget extends StatelessWidget {
  const AddressFormFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    this.isRequired = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: isRequired
          ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }
}
