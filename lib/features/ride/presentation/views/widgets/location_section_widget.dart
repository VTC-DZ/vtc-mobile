import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../shared/widgets/app_text_field.dart';

class LocationSectionWidget extends StatelessWidget {
  const LocationSectionWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.addressController,
    required this.latController,
    required this.lngController,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final TextEditingController addressController;
  final TextEditingController latController;
  final TextEditingController lngController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18.w, color: iconColor),
            SizedBox(width: 8.w),
            Text(label, style: AppTextStyles.labelMedium(context)),
          ],
        ),
        SizedBox(height: 10.h),
        AppTextField(
          controller: addressController,
          hintText: 'Enter address',
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Address is required' : null,
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: latController,
                hintText: 'Latitude',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid';
                  return null;
                },
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text(
                    'Lat',
                    style: AppTextStyles.labelSmall(context).copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: AppTextField(
                controller: lngController,
                hintText: 'Longitude',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid';
                  return null;
                },
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text(
                    'Lng',
                    style: AppTextStyles.labelSmall(context).copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
