import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';

class DashedConnectorWidget extends StatelessWidget {
  const DashedConnectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Container(
              width: 2.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderDefault(context),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
