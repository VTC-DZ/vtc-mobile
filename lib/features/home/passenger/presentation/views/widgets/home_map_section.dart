import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

class HomeMapSection extends StatelessWidget {
  const HomeMapSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(color: AppColors.borderDefault(context), width: 1),
          bottom: BorderSide(color: AppColors.borderDefault(context), width: 1),
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: _MapGridPainter(context: context),
            child: const SizedBox.expand(),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20.r,
                        spreadRadius: 4.r,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: AppColors.white,
                    size: 26.w,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.borderDefault(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 8.r,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text('Map coming soon', style: AppTextStyles.labelSmall(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({required this.context});

  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8EAED);
    final roadColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD5D8DC);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final roadPaint = Paint()
      ..color = roadColor
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.55),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, 0),
      Offset(size.width * 0.75, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
