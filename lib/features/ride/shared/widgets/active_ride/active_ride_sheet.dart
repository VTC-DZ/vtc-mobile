import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';

/// Draggable bottom sheet over the active-ride map, shared by the driver and
/// passenger screens. [header] sits right under the handle so it stays
/// visible when the sheet is collapsed; [children] follow, spaced evenly.
class ActiveRideSheet extends StatelessWidget {
  const ActiveRideSheet({
    super.key,
    required this.header,
    required this.children,
  });

  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.17,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.45],
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ListView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, bottomInset + 16.h),
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault(context),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            header,
            for (final child in children) ...[
              SizedBox(height: 12.h),
              child,
            ],
          ],
        ),
      ),
    );
  }
}
