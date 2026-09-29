import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/utils/fare_formatter.dart';
import '../../../../data/models/driver_ride_models.dart';
import '../../../cubit/available_rides_cubit/available_rides_cubit.dart';
import '../../../cubit/available_rides_cubit/available_rides_state.dart';
import '../../../../../shared/widgets/expiry_indicators.dart';
import 'ride_request_badges.dart';

/// Amber for "below the passenger's offer" — no app-wide warning token exists
/// (same value as the expiry urgency ladder).
const Color _belowOfferAmber = Color(0xFFF59E0B);

/// −/+ stepper increment, in DZD. Steps snap to this grid.
const int _stepDzd = 50;

/// Bottom sheet to enter a bid for a ride request. Returns the entered fare in
/// DZD, or `null` if dismissed. The input is constrained to the server's allowed
/// band (`±50%`, clamped to `[100, 50000]`) so we never round-trip a
/// `400 FARE_OUT_OF_BOUNDS` (see `swagger/epic-03-ride.md` §7).
///
/// Stays in sync with [AvailableRidesCubit] and closes itself once the request
/// expires or leaves the list (taken by another driver, cancelled, …).
Future<int?> showBidSheet(
  BuildContext context, {
  required AvailableRequestCard ride,
}) {
  // Capture the shell-scoped cubit before the modal swaps the context.
  final cubit = context.read<AvailableRidesCubit>();
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _BidSheet(initial: ride),
    ),
  );
}

class _BidSheet extends StatefulWidget {
  const _BidSheet({required this.initial});

  final AvailableRequestCard initial;

  @override
  State<_BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<_BidSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: formatFare(_proposed));
  final FocusNode _focusNode = FocusNode();
  bool _closed = false;

  String get _id => widget.initial.rideRequestId;

  int get _proposed => widget.initial.proposedFare;

  late final int _minFare = math.max(100, (_proposed * 0.5).round());
  late final int _maxFare = math.min(50000, (_proposed * 1.5).round());

  @override
  void initState() {
    super.initState();
    // Rebuild on every edit so the delta, chips and button stay in sync.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int? get _currentValue =>
      int.tryParse(_controller.text.replaceAll(RegExp(r'\D'), ''));

  bool _inRange(int fare) => fare >= _minFare && fare <= _maxFare;

  /// Pops exactly once, however many triggers fire (expiry, removal, submit).
  void _close([int? fare]) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(fare);
  }

  void _setFare(int fare) {
    final text = formatFare(fare.clamp(_minFare, _maxFare));
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Moves to the next/previous multiple of [_stepDzd] (1 320 → 1 350 / 1 300).
  void _step(int direction) {
    HapticFeedback.selectionClick();
    final base = (_currentValue ?? _proposed).clamp(_minFare, _maxFare);
    final next = direction > 0
        ? (base ~/ _stepDzd + 1) * _stepDzd
        : (base - 1) ~/ _stepDzd * _stepDzd;
    _setFare(next);
  }

  /// A quick-pick amount: the passenger's offer ± [percent], rounded to 10 DZD.
  int _presetFare(int percent) {
    if (percent == 0) return _proposed;
    final raw = _proposed * (1 + percent / 100);
    return ((raw / 10).round() * 10).clamp(_minFare, _maxFare);
  }

  void _submit() {
    final fare = _currentValue;
    if (fare == null || !_inRange(fare)) return;
    _close(fare);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AvailableRidesCubit, AvailableRidesState>(
      listenWhen: (prev, curr) => prev.rides != curr.rides,
      listener: (_, state) {
        if (!state.rides.any((r) => r.rideRequestId == _id)) _close();
      },
      child: BlocSelector<AvailableRidesCubit, AvailableRidesState,
          AvailableRequestCard>(
        selector: (state) =>
            state.rides.where((r) => r.rideRequestId == _id).firstOrNull ??
            widget.initial,
        builder: (context, ride) => _buildSheet(context, ride),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, AvailableRequestCard ride) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final fare = _currentValue;
    final valid = fare != null && _inRange(fare);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DragHandle(),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.r),
                      child: ExpiryProgressBar(
                        // Restart the countdown if the server moves the deadline.
                        key: ValueKey(ride.expiresAt),
                        expiresAt: ride.expiresAt,
                        barHeight: 4,
                        onExpired: _close,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Place your bid',
                            style: AppTextStyles.headingSmall(context),
                          ),
                        ),
                        ExpiryCountdown(
                          key: ValueKey(ride.expiresAt),
                          expiresAt: ride.expiresAt,
                          iconSize: 14,
                          textStyle: AppTextStyles.labelMedium(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    _OfferContextCard(ride: ride),
                    SizedBox(height: 22.h),
                    _AmountStepper(
                      controller: _controller,
                      focusNode: _focusNode,
                      canDecrease: fare == null || fare > _minFare,
                      canIncrease: fare == null || fare < _maxFare,
                      onDecrease: () => _step(-1),
                      onIncrease: () => _step(1),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 26.h,
                      child: Center(
                        child: _StatusLine(
                          fare: fare,
                          proposed: _proposed,
                          valid: valid,
                          minFare: _minFare,
                          maxFare: _maxFare,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Allowed ${formatFare(_minFare)} – '
                      '${formatFare(_maxFare)} DZD',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        for (final (i, percent)
                            in const [-10, 0, 10, 20].indexed) ...[
                          if (i > 0) SizedBox(width: 8.w),
                          Expanded(
                            child: _PresetChip(
                              label: switch (percent) {
                                0 => 'Match',
                                > 0 => '+$percent%',
                                _ => '−${-percent}%',
                              },
                              selected: fare == _presetFare(percent),
                              onTap: () => _setFare(_presetFare(percent)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderDefault(context),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                12.h,
                20.w,
                // Safe-area inset matters only when the keyboard is closed;
                // the outer Padding already lifts the sheet above the keyboard.
                (keyboardInset > 0 ? 0 : MediaQuery.paddingOf(context).bottom) +
                    12.h,
              ),
              child: _SubmitButton(
                label:
                    valid ? 'Send bid · ${formatFare(fare)} DZD' : 'Send bid',
                enabled: valid,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
      child: Center(
        child: Container(
          width: 32.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppColors.borderDefault(context),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
      ),
    );
  }
}

/// Passenger's offer and distance to pickup, split by a hairline divider.
class _OfferContextCard extends StatelessWidget {
  const _OfferContextCard({required this.ride});

  final AvailableRequestCard ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault(context)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _ContextStat(
                icon: Icons.payments_rounded,
                label: "Passenger's offer",
                value: '${formatFare(ride.proposedFare)} DZD',
              ),
            ),
            if (ride.distanceMeters != null) ...[
              VerticalDivider(
                width: 24.w,
                thickness: 1,
                color: AppColors.borderDefault(context),
              ),
              Expanded(
                child: _ContextStat(
                  icon: Icons.near_me_rounded,
                  label: 'To pickup',
                  value: formatDistance(ride.distanceMeters!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContextStat extends StatelessWidget {
  const _ContextStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.w, color: AppColors.primary),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        // Scale down rather than truncate so the unit is always visible.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextStyles.headingSmall(context).copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Round −/+ buttons around the big editable amount.
class _AmountStepper extends StatelessWidget {
  const _AmountStepper({
    required this.controller,
    required this.focusNode,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          onTap: canDecrease ? onDecrease : null,
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 40.w),
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [_FareGroupingFormatter()],
                      textAlign: TextAlign.center,
                      cursorColor: AppColors.primary,
                      style: GoogleFonts.inter(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text(context),
                        height: 1.1,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: '0',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 36.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary(context),
                          height: 1.1,
                        ),
                      ),
                      onSubmitted: (_) => focusNode.unfocus(),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  'DZD',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          onTap: canIncrease ? onIncrease : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;

  /// `null` disables the button (at the min/max bound).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.buttonDisabled(context),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48.w,
          height: 48.w,
          child: Icon(
            icon,
            size: 24.w,
            color: enabled
                ? AppColors.primary
                : AppColors.buttonDisabledText(context),
          ),
        ),
      ),
    );
  }
}

/// How the bid compares to the passenger's offer, or why it's invalid.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.fare,
    required this.proposed,
    required this.valid,
    required this.minFare,
    required this.maxFare,
  });

  final int? fare;
  final int proposed;
  final bool valid;
  final int minFare;
  final int maxFare;

  @override
  Widget build(BuildContext context) {
    final fare = this.fare;
    if (fare == null) {
      return _pill(context, 'Enter an amount', AppColors.error);
    }
    if (!valid) {
      return _pill(
        context,
        fare < minFare
            ? 'Minimum is ${formatFare(minFare)} DZD'
            : 'Maximum is ${formatFare(maxFare)} DZD',
        AppColors.error,
      );
    }
    final delta = fare - proposed;
    if (delta == 0) {
      return _pill(context, "Matches passenger's offer",
          AppColors.textSecondary(context));
    }
    return delta > 0
        ? _pill(
            context, '+${formatFare(delta)} DZD above offer', AppColors.primary)
        : _pill(context, '−${formatFare(-delta)} DZD below offer',
            _belowOfferAmber);
  }

  Widget _pill(BuildContext context, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall(context).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tappable quick-pick amount; [selected] when it equals the current bid.
class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10.r);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40.h,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surface(context),
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.borderDefault(context),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.text(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width primary submit button.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: 50.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: enabled ? AppColors.primary : AppColors.buttonDisabled(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12.r),
          splashColor: AppColors.white.withValues(alpha: 0.2),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelLarge(context).copyWith(
                color: enabled
                    ? AppColors.white
                    : AppColors.buttonDisabledText(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps only digits (max 5 — the fare ceiling is 50 000) and groups them with
/// [formatFare] as the driver types, preserving the cursor's digit position.
class _FareGroupingFormatter extends TextInputFormatter {
  static final RegExp _nonDigit = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(_nonDigit, '');
    if (digits.length > 5) digits = digits.substring(0, 5);
    if (digits.isEmpty) return const TextEditingValue();

    // Strip leading zeros ("0120" → "120").
    final text = formatFare(int.parse(digits));

    // Digits left of the cursor in the raw edit → same digit count in [text].
    final cursor = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final digitsBefore = math.min(
      newValue.text.substring(0, cursor).replaceAll(_nonDigit, '').length,
      text.replaceAll(_nonDigit, '').length,
    );
    var offset = 0;
    for (var seen = 0; offset < text.length && seen < digitsBefore; offset++) {
      if (text[offset] != ' ') seen++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
