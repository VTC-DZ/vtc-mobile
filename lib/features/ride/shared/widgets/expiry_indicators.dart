import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Local warning tier for the 30s..10s urgency window — no app-wide token
/// exists for amber, so it's kept as a single shared constant here.
const Color _warningAmber = Color(0xFFF59E0B);

/// Shared green→amber→red urgency ladder used by both the progress bar and the
/// countdown pill, so they can't drift out of sync.
Color _urgencyColor(num remainingSeconds) {
  if (remainingSeconds <= 10) return AppColors.error;
  if (remainingSeconds <= 30) return _warningAmber;
  return AppColors.primary;
}

/// Full-width draining progress bar counting down to [expiresAt] (ISO-8601).
/// Rebuilds every second; only this widget re-renders, not its parent.
class ExpiryProgressBar extends StatefulWidget {
  const ExpiryProgressBar({
    super.key,
    required this.expiresAt,
    required this.barHeight,
    this.onExpired,
  });

  final String expiresAt;
  final double barHeight;
  final VoidCallback? onExpired;

  @override
  State<ExpiryProgressBar> createState() => _ExpiryProgressBarState();
}

class _ExpiryProgressBarState extends State<ExpiryProgressBar> {
  Timer? _timer;
  DateTime? _deadline;
  late double _totalSeconds;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.tryParse(widget.expiresAt);
    if (_deadline != null) {
      _totalSeconds =
          _deadline!.difference(DateTime.now()).inSeconds.toDouble();
      if (_totalSeconds <= 0) _totalSeconds = 1;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (!_expired && _deadline!.isBefore(DateTime.now())) {
          _expired = true;
          widget.onExpired?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _deadline == null
        ? Duration.zero
        : _deadline!.difference(DateTime.now());
    final remainingSeconds =
        remaining.isNegative ? 0.0 : remaining.inSeconds.toDouble();
    final progress = _deadline == null
        ? 0.0
        : (remainingSeconds / _totalSeconds).clamp(0.0, 1.0);
    final color = _urgencyColor(remainingSeconds);

    return LinearProgressIndicator(
      value: progress,
      minHeight: widget.barHeight.h,
      backgroundColor: AppColors.borderDefault(context),
      valueColor: AlwaysStoppedAnimation<Color>(color),
    );
  }
}

/// Live `m:ss` countdown pill to [expiresAt] (ISO-8601), floored at `0:00`.
class ExpiryCountdown extends StatefulWidget {
  const ExpiryCountdown({
    super.key,
    required this.expiresAt,
    this.iconSize = 12,
    this.textStyle,
  });

  final String expiresAt;
  final double iconSize;

  /// Defaults to [AppTextStyles.labelSmall]; the color is always overridden
  /// by the urgency ladder.
  final TextStyle? textStyle;

  @override
  State<ExpiryCountdown> createState() => _ExpiryCountdownState();
}

class _ExpiryCountdownState extends State<ExpiryCountdown> {
  Timer? _timer;
  late DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.tryParse(widget.expiresAt);
    if (_deadline != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _deadline == null
        ? Duration.zero
        : _deadline!.difference(DateTime.now());
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final color = _urgencyColor(clamped.inSeconds);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: widget.iconSize.w, color: color),
          SizedBox(width: 4.w),
          Text(
            _formatRemaining(clamped),
            style: (widget.textStyle ?? AppTextStyles.labelSmall(context))
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

String _formatRemaining(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
