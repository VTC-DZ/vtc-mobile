import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../saved_places/data/address_model.dart';

class AddressTypeIconWidget extends StatelessWidget {
  const AddressTypeIconWidget({super.key, required this.type});

  final AddressType type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      AddressType.home => Icons.home_outlined,
      AddressType.work => Icons.work_outline_rounded,
      AddressType.other => Icons.location_on_outlined,
    };
    return Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22.w),
    );
  }
}
