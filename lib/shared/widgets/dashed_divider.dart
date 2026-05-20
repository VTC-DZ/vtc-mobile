import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 5.h,
      width: double.infinity,
      child: Row(
        children: List.generate(
          40,
          (index) => Expanded(
            child: Container(
              height: 2.h,
              color: index.isEven
                  ? Colors.transparent
                  : AppColors.drawerDivider(context),
            ),
          ),
        ),
      ),
    );
  }
}
