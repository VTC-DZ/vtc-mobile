import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../data/models/driver_ride_models.dart';

/// A single incoming ride request shown to the driver, styled to match the
/// passenger-side `OfferCard` / `RideSummaryCard`. Service & vehicle chips and an
/// optional female-only badge on top, the pickup→dropoff route, a meta row with a
/// live expiry countdown and distance, then the proposed fare and a Bid button.
class AvailableRideCard extends StatelessWidget {
  const AvailableRideCard({
    super.key,
    required this.ride,
    required this.onBid,
  });

  final AvailableRequestCard ride;
  final VoidCallback onBid;

  static const Color _dropoffColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Service / vehicle + female-only badge ---
          Row(
            children: [
              Icon(ride.serviceType.icon, size: 18.w, color: AppColors.primary),
              SizedBox(width: 6.w),
              Text(
                ride.serviceType.label,
                style: AppTextStyles.labelMedium(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 12.w),
              Icon(ride.vehicleCategory.icon,
                  size: 18.w, color: AppColors.textSecondary(context)),
              SizedBox(width: 4.w),
              Text(
                ride.vehicleCategory.label,
                style: AppTextStyles.labelMedium(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              const Spacer(),
              if (ride.femaleOnly) const _FemaleOnlyBadge(),
            ],
          ),
          SizedBox(height: 14.h),

          // --- Route: pickup → dropoff ---
          _LocationRow(
            icon: Icons.trip_origin_rounded,
            iconColor: AppColors.primary,
            address: ride.pickup.address,
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: SizedBox(
              height: 14.h,
              child: VerticalDivider(
                color: AppColors.borderDefault(context),
                thickness: 1.5,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          _LocationRow(
            icon: Icons.location_on_rounded,
            iconColor: _dropoffColor,
            address: ride.dropoff.address,
          ),
          SizedBox(height: 14.h),

          // --- Meta: expiry countdown · distance ---
          Row(
            children: [
              _ExpiryCountdown(expiresAt: ride.expiresAt),
              if (ride.distanceMeters != null) ...[
                _MetaDot(),
                Icon(Icons.straighten_rounded,
                    size: 14.w, color: AppColors.textSecondary(context)),
                SizedBox(width: 4.w),
                Text(
                  _formatDistance(ride.distanceMeters!),
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          Divider(color: AppColors.borderDefault(context), height: 1),
          SizedBox(height: 12.h),

          // --- Fare + Bid ---
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatFare(ride.proposedFare)} DZD',
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'proposed',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  // Override the global theme's infinite minimum width so the
                  // button shrinks to its content inside this Row.
                  minimumSize: Size(0, 44.h),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: onBid,
                child: Text(
                  'Bid',
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDistance(int meters) =>
    meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '$meters m';

/// Space-groups thousands for readability: 1200 → "1 200".
String _formatFare(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class _FemaleOnlyBadge extends StatelessWidget {
  const _FemaleOnlyBadge();

  static const Color _color = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.female_rounded, size: 14.w, color: _color),
          SizedBox(width: 3.w),
          Text(
            'Women',
            style: AppTextStyles.labelSmall(context).copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Text(
        '·',
        style: AppTextStyles.labelSmall(context).copyWith(
          color: AppColors.textSecondary(context),
        ),
      ),
    );
  }
}

/// Live `m:ss` countdown to [expiresAt] (ISO-8601), floored at `0:00`.
class _ExpiryCountdown extends StatefulWidget {
  const _ExpiryCountdown({required this.expiresAt});

  final String expiresAt;

  @override
  State<_ExpiryCountdown> createState() => _ExpiryCountdownState();
}

class _ExpiryCountdownState extends State<_ExpiryCountdown> {
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
    final isUrgent = clamped.inSeconds <= 10;
    final color = isUrgent
        ? const Color(0xFFEF4444)
        : AppColors.textSecondary(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 14.w, color: color),
        SizedBox(width: 4.w),
        Text(
          _formatRemaining(clamped),
          style: AppTextStyles.labelSmall(context).copyWith(color: color),
        ),
      ],
    );
  }
}

String _formatRemaining(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.address,
  });

  final IconData icon;
  final Color iconColor;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.w, color: iconColor),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            address,
            style: AppTextStyles.bodySmall(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
