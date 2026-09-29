import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One row of a vertical stepper: a [marker] on a rail on the left, [child]
/// on the right. Consecutive steps join their rails into one continuous
/// line, so a list of them reads as a route or a timeline.
class RideDetailStep extends StatelessWidget {
  const RideDetailStep({
    super.key,
    required this.marker,
    required this.child,
    required this.lineColor,
    this.isFirst = false,
    this.isLast = false,
    this.dashed = false,
    this.railWidth = 24,
    this.markerTop = 2,
    this.gap = 16,
  });

  final Widget marker;
  final Widget child;
  final Color lineColor;
  final bool isFirst;
  final bool isLast;

  /// Dashed rail (a route) instead of a solid one (a timeline).
  final bool dashed;

  /// Width of the marker column, in design pixels.
  final double railWidth;

  /// Space above the marker, aligning it with the first line of [child].
  final double markerTop;

  /// Space below [child] before the next step (none after the last one).
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rail = CustomPaint(
      size: Size(2.w, double.infinity),
      painter: _RailPainter(color: lineColor, dashed: dashed),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: railWidth.w,
            child: Column(
              children: [
                SizedBox(height: markerTop.h, child: isFirst ? null : rail),
                marker,
                Expanded(child: isLast ? const SizedBox.shrink() : rail),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : gap.h),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    if (!dashed) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      return;
    }
    const dash = 4.0;
    const space = 4.0;
    // Start with a space so the dashes don't touch the markers.
    for (var y = space; y < size.height - space; y += dash + space) {
      final end = (y + dash).clamp(0.0, size.height - space);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.color != color || old.dashed != dashed;
}
