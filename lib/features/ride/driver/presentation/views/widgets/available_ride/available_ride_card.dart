import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/driver_ride_models.dart';
import '../../../../../shared/utils/fare_formatter.dart';
import '../../../../../shared/widgets/ride_route_preview.dart';
import '../../../../../shared/widgets/service_type_chip.dart';
import '../../../../../shared/widgets/expiry_indicators.dart';
import 'ride_request_badges.dart';
import 'ride_request_details_sheet.dart';

/// A single incoming ride request shown to the driver. Service & vehicle chips
/// and an optional female-only badge on top, the pickup→dropoff route, a meta
/// row with a live expiry countdown and distance, then the proposed fare and a
/// Bid button. A draining [LinearProgressIndicator] at the top of the card
/// shows time remaining visually. Tapping the card opens
/// [showRideRequestDetailsSheet] with a map preview and the full details.
///
/// Pass [compact] for the floating [BroadcastOverlay] to render the same card
/// at a tighter density.
///
/// Once the driver has bid, pass [pendingBid]: the timer tracks the bid's own
/// server `expiresAt` instead of the request's, and Ignore/Bid give way to a
/// "Bid sent" pill. The card is then removed by the server's
/// `offer.rejected` / `offer.expired`, not by the local countdown.
class AvailableRideCard extends StatelessWidget {
  const AvailableRideCard({
    super.key,
    required this.ride,
    required this.onBid,
    this.onIgnore,
    this.onExpired,
    this.pendingBid,
    this.compact = false,
  });

  final AvailableRequestCard ride;
  final VoidCallback onBid;
  final VoidCallback? onIgnore;
  final VoidCallback? onExpired;

  /// The driver's live bid on this request, if any.
  final BidResponse? pendingBid;

  /// Shrinks every dimension for the floating [BroadcastOverlay].
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final m = compact ? _CardMetrics.compact : _CardMetrics.normal;
    final bid = pendingBid;
    final deadline = bid?.expiresAt ?? ride.expiresAt;

    return Container(
      margin: EdgeInsets.only(bottom: m.cardBottomMargin.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(m.cardRadius.r),
        border: Border.all(color: AppColors.borderDefault(context), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: m.shadowAlpha),
            blurRadius: m.shadowBlur.r,
            offset: Offset(0, m.shadowOffsetY.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(m.cardRadius.r),
        // Transparent Material above the card's decoration so the ripple shows.
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _openDetails(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Linear timer bar ---
                ExpiryProgressBar(
                  key: ValueKey(deadline),
                  expiresAt: deadline,
                  barHeight: m.progressHeight,
                  onExpired: bid == null ? onExpired : null,
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(m.contentPadding.w,
                      m.contentTop.h, m.contentPadding.w, m.contentPadding.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header: service / vehicle chips / female-only · fare ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ServiceTypeChip(
                                  serviceType: ride.serviceType,
                                  iconSize: m.serviceIconSize,
                                  hPad: m.chipHPad,
                                  vPad: m.chipVPad,
                                ),
                                if (ride.vehicleCategory != null)
                                  VehicleCategoryChip(
                                    category: ride.vehicleCategory!,
                                    iconSize: m.serviceIconSize,
                                    hPad: m.chipHPad,
                                    vPad: m.chipVPad,
                                  ),
                                if (ride.femaleOnly) const FemaleOnlyBadge(),
                              ],
                            ),
                          ),
                          SizedBox(width: 6.w),
                          _FareBlock(
                            amount: ride.proposedFare,
                            fareFontSize: m.fareFontSize,
                            captionFontSize: m.fareCaptionSize,
                          ),
                        ],
                      ),

                      SizedBox(height: m.gapHeaderRoute.h),

                      // --- Route: pickup → dropoff ---
                      RideRoutePreview(
                        pickup: ride.pickup.address,
                        dropoff: ride.dropoff.address,
                        iconSize: m.locationIconSize,
                        spacing: m.locationSpacing,
                        connectorHeight: m.connectorHeight,
                        connectorInset: m.connectorInset,
                        iconTopPadding: 0,
                        addressStyle: AppTextStyles.bodySmall(context),
                      ),
                      SizedBox(height: m.gapRouteFooter.h),

                      // --- Footer: countdown · distance · Ignore · Bid ---
                      Row(
                        children: [
                          ExpiryCountdown(
                            key: ValueKey(deadline),
                            expiresAt: deadline,
                            iconSize: m.countdownIconSize,
                          ),
                          if (ride.distanceMeters != null) ...[
                            _MetaDot(),
                            Icon(Icons.straighten_rounded,
                                size: m.metaIconSize.w,
                                color: AppColors.textSecondary(context)),
                            SizedBox(width: 2.w),
                            Text(
                              formatDistance(ride.distanceMeters!),
                              style: AppTextStyles.labelSmall(context).copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (bid != null)
                            _BidSentPill(fare: bid.fare, height: m.buttonHeight)
                          else ...[
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    AppColors.textSecondary(context),
                                side: BorderSide(
                                    color: AppColors.borderDefault(context)),
                                minimumSize: Size(0, m.buttonHeight.h),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.symmetric(
                                    horizontal: m.ignoreButtonHPad.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(m.buttonRadius.r),
                                ),
                              ),
                              onPressed: onIgnore,
                              child: Text(
                                'Ignore',
                                style:
                                    AppTextStyles.labelSmall(context).copyWith(
                                  color: AppColors.textSecondary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: m.buttonGap.w),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                minimumSize: Size(0, m.buttonHeight.h),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.symmetric(
                                    horizontal: m.bidButtonHPad.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(m.buttonRadius.r),
                                ),
                              ),
                              onPressed: onBid,
                              child: Text(
                                'Bid',
                                style:
                                    AppTextStyles.labelSmall(context).copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the full details sheet (map, addresses, distances) and forwards
  /// the driver's choice to the same callbacks the card's buttons use.
  Future<void> _openDetails(BuildContext context) async {
    final action = await showRideRequestDetailsSheet(context, ride: ride);
    // A live bid can't be re-placed or withdrawn from here.
    if (pendingBid != null) return;
    switch (action) {
      case RideRequestAction.bid:
        onBid();
      case RideRequestAction.ignore:
        onIgnore?.call();
      case null:
        break;
    }
  }
}

/// All tunable dimensions for [AvailableRideCard], stored as raw values so the
/// `.w/.h/.r` ScreenUtil scaling is applied at each use site. Two presets:
/// [normal] (list view) and [compact] (floating overlay).
class _CardMetrics {
  const _CardMetrics({
    required this.cardBottomMargin,
    required this.cardRadius,
    required this.contentPadding,
    required this.contentTop,
    required this.serviceIconSize,
    required this.gapHeaderRoute,
    required this.connectorHeight,
    required this.connectorInset,
    required this.gapRouteFooter,
    required this.metaIconSize,
    required this.countdownIconSize,
    required this.buttonHeight,
    required this.buttonRadius,
    required this.buttonGap,
    required this.ignoreButtonHPad,
    required this.bidButtonHPad,
    required this.progressHeight,
    required this.locationIconSize,
    required this.locationSpacing,
    required this.shadowAlpha,
    required this.shadowBlur,
    required this.shadowOffsetY,
    required this.chipHPad,
    required this.chipVPad,
    required this.fareFontSize,
    required this.fareCaptionSize,
  });

  final double cardBottomMargin; // .h
  final double cardRadius; // .r
  final double contentPadding; // .w
  final double contentTop; // .h
  final double serviceIconSize; // .w
  final double gapHeaderRoute; // .h
  final double connectorHeight; // .h
  final double connectorInset; // .w
  final double gapRouteFooter; // .h
  final double metaIconSize; // .w
  final double countdownIconSize; // .w
  final double buttonHeight; // .h
  final double buttonRadius; // .r
  final double buttonGap; // .w
  final double ignoreButtonHPad; // .w
  final double bidButtonHPad; // .w
  final double progressHeight; // .h
  final double locationIconSize; // .w
  final double locationSpacing; // .w
  final double shadowAlpha;
  final double shadowBlur; // .r
  final double shadowOffsetY; // .h
  final double chipHPad; // .w
  final double chipVPad; // .h
  final double fareFontSize; // .sp
  final double fareCaptionSize; // .sp

  /// Tightened base size used in the available-rides list.
  static const normal = _CardMetrics(
    cardBottomMargin: 8,
    cardRadius: 12,
    contentPadding: 10,
    contentTop: 8,
    serviceIconSize: 14,
    gapHeaderRoute: 6,
    connectorHeight: 10,
    connectorInset: 6.5,
    gapRouteFooter: 8,
    metaIconSize: 12,
    countdownIconSize: 12,
    buttonHeight: 30,
    buttonRadius: 8,
    buttonGap: 6,
    ignoreButtonHPad: 10,
    bidButtonHPad: 20,
    progressHeight: 3,
    locationIconSize: 14,
    locationSpacing: 6,
    shadowAlpha: 0.06,
    shadowBlur: 12,
    shadowOffsetY: 3,
    chipHPad: 8,
    chipVPad: 4,
    fareFontSize: 17,
    fareCaptionSize: 10,
  );

  /// One step tighter — used by the floating [BroadcastOverlay].
  static const compact = _CardMetrics(
    cardBottomMargin: 4,
    cardRadius: 10,
    contentPadding: 8,
    contentTop: 6,
    serviceIconSize: 13,
    gapHeaderRoute: 4,
    connectorHeight: 8,
    connectorInset: 6,
    gapRouteFooter: 6,
    metaIconSize: 11,
    countdownIconSize: 11,
    buttonHeight: 28,
    buttonRadius: 8,
    buttonGap: 5,
    ignoreButtonHPad: 8,
    bidButtonHPad: 14,
    progressHeight: 2.5,
    locationIconSize: 13,
    locationSpacing: 5,
    shadowAlpha: 0.05,
    shadowBlur: 8,
    shadowOffsetY: 2,
    chipHPad: 6,
    chipVPad: 3,
    fareFontSize: 14,
    fareCaptionSize: 9,
  );
}

/// Right-aligned proposed-fare block, the card's primary visual hook.
class _FareBlock extends StatelessWidget {
  const _FareBlock({
    required this.amount,
    required this.fareFontSize,
    required this.captionFontSize,
  });

  final int amount;
  final double fareFontSize;
  final double captionFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${formatFare(amount)} DZD',
          style: AppTextStyles.headingSmall(context).copyWith(
            fontSize: fareFontSize.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),
        Text(
          'proposed fare',
          style: AppTextStyles.labelSmall(context).copyWith(
            color: AppColors.textSecondary(context),
            fontSize: captionFontSize.sp,
          ),
        ),
      ],
    );
  }
}

/// Non-interactive stand-in for Ignore/Bid while the driver's bid is live.
class _BidSentPill extends StatelessWidget {
  const _BidSentPill({required this.fare, required this.height});

  final int fare;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 14.w, color: AppColors.primary),
          SizedBox(width: 4.w),
          Text(
            'Bid sent · ${formatFare(fare)} DZD',
            style: AppTextStyles.labelSmall(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
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
