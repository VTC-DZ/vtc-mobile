import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/passenger_ride_models.dart';

class OfferCard extends StatefulWidget {
  const OfferCard({
    super.key,
    required this.index,
    required this.offer,
    required this.isAccepting,
    required this.onAccept,
    required this.onRefuse,
    required this.onExpired,
  });

  final int index;
  final OfferEntry offer;
  final bool isAccepting;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  final VoidCallback onExpired;

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = max(
      0,
      DateTime.parse(widget.offer.expiresAt)
          .difference(DateTime.now())
          .inSeconds,
    );
    if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    } else {
      // Already expired when mounted — remove on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onExpired());
    }
  }

  void _tick(Timer _) {
    if (_secondsLeft <= 1) {
      _timer?.cancel();
      widget.onExpired();
    } else {
      setState(() => _secondsLeft--);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etaMin = widget.offer.etaSeconds != null
        ? (widget.offer.etaSeconds! / 60).ceil()
        : null;
    final timerColor = _secondsLeft <= 10 ? AppColors.error : AppColors.primary;

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
          Text(
            '#${widget.index}',
            style: AppTextStyles.labelSmall(context).copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 22.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.offer.driverFullName,
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 14.w, color: const Color(0xFFF59E0B)),
                        SizedBox(width: 2.w),
                        Text(
                          widget.offer.driverRatingAvg != null
                              ? widget.offer.driverRatingAvg!.toStringAsFixed(1)
                              : '—',
                          style: AppTextStyles.labelSmall(context).copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Icon(Icons.directions_car_rounded,
                            size: 14.w,
                            color: AppColors.textSecondary(context)),
                        SizedBox(width: 3.w),
                        Flexible(
                          child: Text(
                            widget.offer.vehiclePlate != null
                                ? '${widget.offer.vehicleModel} · ${widget.offer.vehiclePlate}'
                                : widget.offer.vehicleModel,
                            style: AppTextStyles.labelSmall(context).copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.offer.fare} DZD',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  if (etaMin != null)
                    Text(
                      '$etaMin min away',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: timerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${_secondsLeft}s',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: timerColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: widget.isAccepting ? null : widget.onRefuse,
                  child: Text(
                    'Refuse',
                    style: AppTextStyles.labelMedium(context).copyWith(
                      color: widget.isAccepting
                          ? AppColors.buttonDisabledText(context)
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: widget.isAccepting ? null : widget.onAccept,
                  child: Text(
                    'Accept',
                    style: AppTextStyles.labelMedium(context).copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
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
