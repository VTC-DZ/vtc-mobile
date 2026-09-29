import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/passenger_ride_models.dart';
import '../../../../../shared/utils/fare_formatter.dart';
import '../../../../../shared/widgets/expiry_indicators.dart';
import '../../../../../shared/widgets/ride_route_card.dart';
import '../../../cubit/waiting_offers_cubit/waiting_offers_cubit.dart';
import '../../../cubit/waiting_offers_cubit/waiting_offers_state.dart';
import 'offer_parts.dart';

/// What the passenger chose in the details sheet; `null` means dismissed.
enum OfferAction { accept, decline }

/// Full details for a driver's offer: who the driver is, their price against
/// the passenger's own, ETA, vehicle and plate, and the trip — with the same
/// Decline / Accept actions as the card.
///
/// Stays in sync with [WaitingOffersCubit] and closes itself once the offer
/// expires or leaves the list (withdrawn, expired, refused, …).
Future<OfferAction?> showOfferDetailsSheet(
  BuildContext context, {
  required OfferEntry offer,
  required WaitingOffersArgs args,
}) {
  // Capture the route-scoped cubit before the modal swaps the context.
  final cubit = context.read<WaitingOffersCubit>();
  return showModalBottomSheet<OfferAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _OfferDetailsSheet(offer: offer, args: args),
    ),
  );
}

class _OfferDetailsSheet extends StatefulWidget {
  const _OfferDetailsSheet({required this.offer, required this.args});

  final OfferEntry offer;
  final WaitingOffersArgs args;

  @override
  State<_OfferDetailsSheet> createState() => _OfferDetailsSheetState();
}

class _OfferDetailsSheetState extends State<_OfferDetailsSheet> {
  bool _closed = false;

  /// Pops exactly once, however many triggers fire (expiry, removal, button).
  void _close([OfferAction? action]) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final args = widget.args;
    final pickup = args.pickup;
    final dropoff = args.dropoff;

    return BlocListener<WaitingOffersCubit, WaitingOffersState>(
      listenWhen: (prev, curr) => prev.offers != curr.offers,
      listener: (_, state) {
        if (!state.offers.any((o) => o.offerId == offer.offerId)) _close();
      },
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
                        key: ValueKey(offer.expiresAt),
                        expiresAt: offer.expiresAt,
                        barHeight: 4,
                        onExpired: _close,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _DriverHero(offer: offer),
                    SizedBox(height: 16.h),
                    _PriceCard(
                      fare: offer.fare,
                      proposedFare: args.proposedFare,
                    ),
                    SizedBox(height: 12.h),
                    _StatsCard(offer: offer),
                    SizedBox(height: 12.h),
                    _VehicleCard(
                      model: offer.vehicleModel,
                      plate: offer.vehiclePlate,
                    ),
                    if (pickup != null && dropoff != null) ...[
                      SizedBox(height: 18.h),
                      Text(
                        'Your trip',
                        style: AppTextStyles.labelLarge(context).copyWith(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      RideRouteCard(pickup: pickup, dropoff: dropoff),
                    ],
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
                MediaQuery.paddingOf(context).bottom + 12.h,
              ),
              child: BlocSelector<WaitingOffersCubit, WaitingOffersState,
                  (bool, String)>(
                selector: (state) => (
                  state.acceptStatus == AcceptStatus.loading,
                  state.acceptingOfferId,
                ),
                builder: (context, accepting) => OfferActions(
                  fare: offer.fare,
                  height: 50,
                  isAccepting: accepting.$1,
                  isAcceptingThis:
                      accepting.$1 && accepting.$2 == offer.offerId,
                  onAccept: () => _close(OfferAction.accept),
                  onDecline: () => _close(OfferAction.decline),
                ),
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

/// Big avatar, name and rating, with the offer countdown on the right.
class _DriverHero extends StatelessWidget {
  const _DriverHero({required this.offer});

  final OfferEntry offer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DriverAvatar(name: offer.driverFullName, size: 64),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.driverFullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingSmall(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4.h),
              DriverRating(ratingAvg: offer.driverRatingAvg),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        ExpiryCountdown(
          key: ValueKey(offer.expiresAt),
          expiresAt: offer.expiresAt,
          iconSize: 14,
          textStyle: AppTextStyles.labelMedium(context),
        ),
      ],
    );
  }
}

/// The driver's price, how it compares, and the passenger's own offer.
class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.fare, required this.proposedFare});

  final int fare;
  final int proposedFare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Driver's price",
            style: AppTextStyles.labelSmall(context).copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${formatFare(fare)} DZD',
                    style: AppTextStyles.headingMedium(context).copyWith(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.15,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              OfferFareDelta(fare: fare, proposedFare: proposedFare),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Your offer: ${formatFare(proposedFare)} DZD',
            style: AppTextStyles.labelMedium(context).copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Arrives in" and "Rating", split by a hairline divider.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.offer});

  final OfferEntry offer;

  @override
  Widget build(BuildContext context) {
    final eta = etaMinutes(offer.etaSeconds);
    final rating = offer.driverRatingAvg;

    return _SurfaceCard(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                icon: Icons.schedule_rounded,
                label: 'Arrives in',
                value: eta == null ? '—' : '~$eta min',
              ),
            ),
            VerticalDivider(
              width: 24.w,
              thickness: 1,
              color: AppColors.borderDefault(context),
            ),
            Expanded(
              child: _Stat(
                icon: Icons.star_rounded,
                label: 'Rating',
                value:
                    rating == null ? 'New' : '${rating.toStringAsFixed(1)} / 5',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
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

/// Car icon, model, and the plate styled like a real licence plate.
class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.model, required this.plate});

  final String model;
  final String? plate;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.directions_car_rounded,
              size: 22.w,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  model,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge(context).copyWith(
                    color: AppColors.text(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (plate != null) ...[
            SizedBox(width: 10.w),
            VehiclePlateChip(plate: plate!, large: true),
          ],
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault(context)),
      ),
      child: child,
    );
  }
}
