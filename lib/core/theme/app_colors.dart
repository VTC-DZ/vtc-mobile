// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

/// Design-system colour tokens — all colours are defined once here.
abstract final class AppColors {
  AppColors._();

  // ── Brand Primary ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF00C853);
  static const Color primaryDark = Color(0xFF00953E);

  // ── Constant Base Colors ──────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0A0A0A);
  static const Color error = Color(0xFFEF4444);

  // ── Dynamic Colors (Context Aware) ────────────────────────────────────────

  /// General dark mode check helper if needed
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? const Color(0xFF121212) : const Color(0xFFFDFBF7);

  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1A1A) : const Color(0xFFF3F0E9);

  static Color bottomBarSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF202327) : const Color(0xFFE9E4D9);

  static Color drawerBackground(BuildContext context) =>
      isDark(context) ? black : const Color(0xFFF3F0E9);

  static Color drawerText(BuildContext context) =>
      isDark(context) ? white : const Color(0xFF151511);

  static Color drawerTextMuted(BuildContext context) =>
      drawerText(context).withValues(alpha: isDark(context) ? 0.68 : 0.62);

  static Color drawerItemSelected(BuildContext context) => isDark(context)
      ? white.withValues(alpha: 0.1)
      : black.withValues(alpha: 0.06);

  static Color drawerDivider(BuildContext context) =>
      drawerText(context).withValues(alpha: isDark(context) ? 0.34 : 0.24);

  static Color text(BuildContext context) => isDark(context) ? white : black;

  static Color textSecondary(BuildContext context) => isDark(context)
      ? white.withValues(alpha: 0.7)
      : black.withValues(alpha: 0.7);

  static Color borderDefault(BuildContext context) =>
      text(context).withValues(alpha: 0.15);

  static Color buttonDisabled(BuildContext context) =>
      text(context).withValues(alpha: 0.12);

  static Color buttonDisabledText(BuildContext context) =>
      text(context).withValues(alpha: 0.38);
}
