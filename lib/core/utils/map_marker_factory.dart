import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Paints the app's custom map markers into [BitmapDescriptor]s.
///
/// Google Maps markers can't be Flutter widgets, so the pin/badge visuals are
/// drawn with a [Canvas] at the device pixel ratio. Results are cached by
/// their parameters so rebuilds don't repaint.
abstract final class MapMarkerFactory {
  MapMarkerFactory._();

  static final Map<String, Future<BitmapDescriptor>> _cache = {};

  static double get _dpr =>
      ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 3;

  /// Colored circle with a white [icon] glyph, optionally with a soft glow.
  /// Anchor at `Offset(0.5, 0.5)`.
  static Future<BitmapDescriptor> circle({
    required Color color,
    required IconData icon,
    double iconSize = 16,
    double padding = 6,
    bool glow = false,
    Color? iconColor,
    Color? borderColor,
  }) {
    final key =
        'circle|${color.toARGB32()}|${icon.codePoint}|$iconSize|$padding|$glow|${iconColor?.toARGB32()}|${borderColor?.toARGB32()}';
    return _cache.putIfAbsent(key, () {
      final glowPad = glow ? 10.0 : 0.0;
      final diameter = iconSize + padding * 2;
      final side = diameter + glowPad * 2;
      return _render(Size(side, side), (canvas) {
        _drawBadge(
          canvas,
          center: Offset(side / 2, side / 2),
          diameter: diameter,
          color: color,
          icon: icon,
          iconSize: iconSize,
          glow: glow,
          iconColor: iconColor ?? Colors.white,
          borderColor: borderColor,
        );
      });
    });
  }

  /// Circle badge with a white label chip floating above it. The bottom of the
  /// badge sits on the point — anchor at `Offset(0.5, 1)`.
  static Future<BitmapDescriptor> labeled({
    required Color color,
    required IconData icon,
    required String label,
    bool glow = false,
  }) {
    final key = 'labeled|${color.toARGB32()}|${icon.codePoint}|$label|$glow';
    return _cache.putIfAbsent(key, () {
      const iconSize = 18.0;
      const padding = 6.0;
      const glowPad = 10.0;
      const gap = 4.0;
      const chipPadH = 8.0;
      const chipPadV = 3.0;
      const chipMaxTextWidth = 84.0;

      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: chipMaxTextWidth);

      final chipW = text.width + chipPadH * 2;
      final chipH = text.height + chipPadV * 2;
      const diameter = iconSize + padding * 2;
      final width = math.max(chipW + 8, diameter + glowPad * 2);
      final height = 4 + chipH + gap + diameter + glowPad;

      return _render(Size(width, height), (canvas) {
        final chipRect = RRect.fromRectAndRadius(
          Rect.fromLTWH((width - chipW) / 2, 4, chipW, chipH),
          const Radius.circular(8),
        );
        canvas.drawRRect(
          chipRect.shift(const Offset(0, 2)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawRRect(chipRect, Paint()..color = Colors.white);
        canvas.drawRRect(
          chipRect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        text.paint(
          canvas,
          Offset((width - text.width) / 2, 4 + chipPadV),
        );

        _drawBadge(
          canvas,
          center: Offset(width / 2, 4 + chipH + gap + diameter / 2),
          diameter: diameter,
          color: color,
          icon: icon,
          iconSize: iconSize,
          glow: glow,
          iconColor: Colors.white,
        );
      });
    });
  }

  /// A plain drop-pin glyph (`location_on`) with a shadow. Anchor at
  /// `Offset(0.5, 1)`.
  static Future<BitmapDescriptor> pin({
    required Color color,
    double size = 44,
  }) {
    final key = 'pin|${color.toARGB32()}|$size';
    return _cache.putIfAbsent(key, () {
      return _render(Size(size, size), (canvas) {
        _drawIcon(
          canvas,
          Icons.location_on_rounded,
          size: size,
          color: color,
          topLeft: Offset.zero,
          shadow: Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        );
      });
    });
  }

  static void _drawBadge(
    Canvas canvas, {
    required Offset center,
    required double diameter,
    required Color color,
    required IconData icon,
    required double iconSize,
    required bool glow,
    required Color iconColor,
    Color? borderColor,
  }) {
    final radius = diameter / 2;
    if (glow) {
      canvas.drawCircle(
        center,
        radius + 2,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = color);
    if (borderColor != null) {
      canvas.drawCircle(
        center,
        radius - 1.25,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    _drawIcon(
      canvas,
      icon,
      size: iconSize,
      color: iconColor,
      topLeft: center - Offset(iconSize / 2, iconSize / 2),
    );
  }

  static void _drawIcon(
    Canvas canvas,
    IconData icon, {
    required double size,
    required Color color,
    required Offset topLeft,
    Shadow? shadow,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
          height: 1,
          shadows: shadow == null ? null : [shadow],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      topLeft +
          Offset((size - painter.width) / 2, (size - painter.height) / 2),
    );
  }

  static Future<BitmapDescriptor> _render(
    Size logicalSize,
    void Function(Canvas canvas) paint,
  ) async {
    final dpr = _dpr;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    paint(canvas);
    final image = await recorder.endRecording().toImage(
          (logicalSize.width * dpr).ceil(),
          (logicalSize.height * dpr).ceil(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }
}
