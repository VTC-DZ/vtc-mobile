import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../shared/widgets/app_text_field.dart';
import '../../../../../../shared/widgets/primary_button.dart';

/// Bottom sheet to enter a bid for a ride request. Returns the entered fare in
/// DZD, or `null` if dismissed. The input is constrained to the server's allowed
/// band (`±50%`, clamped to `[100, 50000]`) so we never round-trip a
/// `400 FARE_OUT_OF_BOUNDS` (see `swagger/epic-03-ride.md` §7).
Future<int?> showBidSheet(
  BuildContext context, {
  required int proposedFare,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    isScrollControlled: true,
    builder: (_) => _BidSheet(proposedFare: proposedFare),
  );
}

class _BidSheet extends StatefulWidget {
  const _BidSheet({required this.proposedFare});

  final int proposedFare;

  @override
  State<_BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<_BidSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.proposedFare.toString());
  late final int _minFare = math.max(100, (widget.proposedFare * 0.5).round());
  late final int _maxFare =
      math.min(50000, (widget.proposedFare * 1.5).round());
  String _error = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final fare = int.tryParse(_controller.text.trim());
    if (fare == null) {
      setState(() => _error = 'Enter a fare amount');
      return;
    }
    if (fare < _minFare || fare > _maxFare) {
      setState(() => _error = 'Fare must be between $_minFare and $_maxFare DZD');
      return;
    }
    Navigator.pop(context, fare);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        0,
        16.w,
        16.h + MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.circular(28.r),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            SizedBox(height: 20.h),
            Text(
              'Place your bid',
              style: AppTextStyles.headingSmall(context),
            ),
            SizedBox(height: 4.h),
            Text(
              'Proposed ${widget.proposedFare} DZD · allowed $_minFare–$_maxFare',
              style: AppTextStyles.labelSmall(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _controller,
              hintText: 'Your fare (DZD)',
              prefixIcon: const Icon(Icons.payments_outlined),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              error: _error,
              onChanged: (_) {
                if (_error.isNotEmpty) setState(() => _error = '');
              },
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: 20.h),
            PrimaryButton(label: 'Submit bid', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
