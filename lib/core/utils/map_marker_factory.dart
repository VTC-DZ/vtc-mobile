import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A painted marker bitmap plus the anchor that places its "point" exactly on
/// the marker's coordinate (e.g. the tip of a pin, not the bottom of the
/// image, which also contains the ground shadow).
final class MapMarkerIcon {
  const MapMarkerIcon(this.descriptor, this.anchor);

  final BitmapDescriptor descriptor;
  final Offset anchor;
}

/// Paints the app's custom map markers into [BitmapDescriptor]s.
///
/// Google Maps markers can't be Flutter widgets, so the pin/car visuals are
/// drawn with a [Canvas] at the device pixel ratio. Results are cached by
/// their parameters so rebuilds don't repaint.
abstract final class MapMarkerFactory {
  MapMarkerFactory._();

  static final Map<String, Future<BitmapDescriptor>> _cache = {};

  static double get _dpr =>
      ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 3;

  static const Color _labelChipColor = Color(0xFF111827);

  /// Teardrop pin in [color] with a white disc holding a colored [icon], a
  /// ground shadow under the tip, and an optional dark [label] chip floating
  /// above it. Use the returned [MapMarkerIcon.anchor] — it sits on the tip.
  static Future<MapMarkerIcon> locationPin({
    required Color color,
    required IconData icon,
    String? label,
  }) async {
    const headRadius = 17.0;
    const tipDistance = 29.0; // head center → tip
    const outline = 2.0;
    const shadowPad = 4.0;
    const chipPadH = 8.0;
    const chipPadV = 4.0;
    const chipGap = 5.0;

    final text = label == null
        ? null
        : (TextPainter(
            text: TextSpan(
              text: label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: 96));

    final chipW = text == null ? 0.0 : text.width + chipPadH * 2;
    final chipH = text == null ? 0.0 : text.height + chipPadV * 2;
    const pinW = (headRadius + outline) * 2;
    final width = math.max(chipW, pinW) + shadowPad * 2;
    final headTop = shadowPad + (text == null ? 0 : chipH + chipGap);
    final headCenter = Offset(width / 2, headTop + outline + headRadius);
    final tip = headCenter + const Offset(0, tipDistance);
    final height = tip.dy + shadowPad;
    final anchor = Offset(0.5, tip.dy / height);

    final key =
        'locationPin|${color.toARGB32()}|${icon.codePoint}|${label ?? ''}';
    final descriptor = await _cache.putIfAbsent(key, () {
      return _render(Size(width, height), (canvas) {
        // Ground shadow under the tip.
        canvas.drawOval(
          Rect.fromCenter(center: tip, width: 14, height: 5),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );

        final body = _teardrop(headCenter, headRadius + outline, tip);
        canvas.drawPath(
          body.shift(const Offset(0, 2)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawPath(body, Paint()..color = Colors.white);
        canvas.drawPath(
          _teardrop(headCenter, headRadius, tip - const Offset(0, outline)),
          Paint()..color = color,
        );

        canvas.drawCircle(headCenter, 11, Paint()..color = Colors.white);
        _drawIcon(
          canvas,
          icon,
          size: 14,
          color: color,
          topLeft: headCenter - const Offset(7, 7),
        );

        if (text != null) {
          final chipRect = RRect.fromRectAndRadius(
            Rect.fromLTWH((width - chipW) / 2, shadowPad, chipW, chipH),
            Radius.circular(chipH / 2),
          );
          canvas.drawRRect(
            chipRect.shift(const Offset(0, 1.5)),
            Paint()
              ..color = Colors.black.withValues(alpha: 0.2)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
          canvas.drawRRect(chipRect, Paint()..color = _labelChipColor);
          text.paint(
            canvas,
            Offset((width - text.width) / 2, shadowPad + chipPadV),
          );
        }
      });
    });
    return MapMarkerIcon(descriptor, anchor);
  }

  /// Top-down car pointing north (up). Anchor at `Offset(0.5, 0.5)` and use
  /// with `flat: true` + `rotation: <bearing>` so it turns with the map.
  static Future<BitmapDescriptor> car({Color accent = Colors.green}) {
    final key = 'car|${accent.toARGB32()}';
    return _cache.putIfAbsent(key, () {
      const size = Size(36, 58);
      const bodyW = 22.0;
      const bodyL = 44.0;
      final c = Offset(size.width / 2, size.height / 2);
      final top = c.dy - bodyL / 2;
      final bodyRect = Rect.fromCenter(center: c, width: bodyW, height: bodyL);
      final body = RRect.fromRectAndCorners(
        bodyRect,
        topLeft: const Radius.circular(9),
        topRight: const Radius.circular(9),
        bottomLeft: const Radius.circular(7),
        bottomRight: const Radius.circular(7),
      );
      const glass = Color(0xFF1F2937);

      return _render(size, (canvas) {
        canvas.drawRRect(
          body.shift(const Offset(0, 2)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );

        // Side mirrors
        final mirror = Paint()..color = const Color(0xFF94A3B8);
        for (final dx in [-bodyW / 2 - 1.5, bodyW / 2 + 1.5]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(c.dx + dx, top + 14),
              width: 4,
              height: 3,
            ),
            mirror,
          );
        }

        canvas.drawRRect(body, Paint()..color = Colors.white);
        canvas.drawRRect(
          body,
          Paint()
            ..color = const Color(0xFFCBD5E1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        // Windshield (front) and rear window.
        _drawSoft(
            canvas, _trapezoid(c.dx, top + 11, 15, top + 17.5, 13), glass);
        _drawSoft(canvas, _trapezoid(c.dx, top + 33, 13, top + 37, 15), glass);

        // Roof with a small accent light.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(c.dx - 7.5, top + 18.5, c.dx + 7.5, top + 31.5),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFFF1F5F9),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(c.dx, top + 25),
              width: 8,
              height: 3.5,
            ),
            const Radius.circular(1.5),
          ),
          Paint()..color = accent,
        );

        // Head- and taillights.
        final head = Paint()..color = const Color(0xFFFCD34D);
        final tail = Paint()..color = const Color(0xFFEF4444);
        for (final dx in [-6.5, 6.5]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(c.dx + dx, top + 2.5),
                width: 5,
                height: 2,
              ),
              const Radius.circular(1),
            ),
            head,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(c.dx + dx, top + bodyL - 1.8),
                width: 5,
                height: 1.8,
              ),
              const Radius.circular(1),
            ),
            tail,
          );
        }
      });
    });
  }

  /// Google-style "you are here" dot: translucent halo, white ring, solid
  /// center. Anchor at `Offset(0.5, 0.5)`.
  static Future<BitmapDescriptor> userDot({
    Color color = const Color(0xFF2563EB),
  }) {
    final key = 'userDot|${color.toARGB32()}';
    return _cache.putIfAbsent(key, () {
      const side = 34.0;
      const c = Offset(side / 2, side / 2);
      return _render(const Size(side, side), (canvas) {
        canvas.drawCircle(
            c, 16, Paint()..color = color.withValues(alpha: 0.18));
        canvas.drawCircle(
          c + const Offset(0, 1),
          9,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        canvas.drawCircle(c, 9, Paint()..color = Colors.white);
        canvas.drawCircle(c, 6.5, Paint()..color = color);
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

  /// Circle of [radius] around [center] whose bottom tapers into a point at
  /// [tip] (tangent lines from the tip to the circle).
  static Path _teardrop(Offset center, double radius, Offset tip) {
    final d = (tip - center).distance;
    final phi = math.acos(radius / d);
    final rect = Rect.fromCircle(center: center, radius: radius);
    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        center.dx - radius * math.sin(phi),
        center.dy + radius * math.cos(phi),
      )
      ..arcTo(rect, math.pi / 2 + phi, 2 * math.pi - 2 * phi, false)
      ..close();
  }

  /// Horizontal trapezoid centered on [cx], [topWidth] wide at [topY] and
  /// [bottomWidth] wide at [bottomY].
  static Path _trapezoid(
    double cx,
    double topY,
    double topWidth,
    double bottomY,
    double bottomWidth,
  ) =>
      Path()
        ..moveTo(cx - topWidth / 2, topY)
        ..lineTo(cx + topWidth / 2, topY)
        ..lineTo(cx + bottomWidth / 2, bottomY)
        ..lineTo(cx - bottomWidth / 2, bottomY)
        ..close();

  /// Fills [path] and strokes it with round joins so small shapes get soft
  /// corners.
  static void _drawSoft(Canvas canvas, Path path, Color color) {
    canvas
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
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
      topLeft + Offset((size - painter.width) / 2, (size - painter.height) / 2),
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
