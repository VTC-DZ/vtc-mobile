import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../models/shared_ride_models.dart';
import 'ride_detail_route_map.dart';

/// Layout shared by the driver and passenger ride-detail screens: a map hero
/// of the ride's route that collapses into a pinned "Ride details" bar, and
/// the [children] on a rounded sheet overlapping it.
///
/// Without a drawable route the hero is a soft gradient in the outcome's
/// color, carrying its icon.
class RideDetailScaffold extends StatelessWidget {
  const RideDetailScaffold({
    super.key,
    required this.onBack,
    required this.children,
    this.routePoints,
    this.state,
  });

  final VoidCallback onBack;
  final List<Widget> children;

  /// Path to draw on the hero map; fewer than two points shows the fallback.
  final List<LatLng>? routePoints;

  /// Tints the fallback hero; `null` while unknown (still loading).
  final RideOutcome? state;

  static const double _expandedHeight = 300;
  static const double _sheetOverlap = 24;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final points = routePoints;
    final hasRoute = points != null && points.length >= 2;
    final background = AppColors.background(context);

    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _expandedHeight.h,
            backgroundColor: background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leadingWidth: 64.w,
            leading: Center(child: _BackButton(onTap: onBack)),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final minHeight =
                    topInset + kToolbarHeight + _sheetOverlap.h;
                final maxHeight = topInset + _expandedHeight.h;
                final expanded = ((constraints.maxHeight - minHeight) /
                        (maxHeight - minHeight))
                    .clamp(0.0, 1.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fixed-size hero, clipped and lifted as the bar shrinks
                    // (resizing a native map view every frame would stutter).
                    ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minHeight: maxHeight,
                        maxHeight: maxHeight,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            (maxHeight - constraints.maxHeight) * 0.5,
                          ),
                          child: hasRoute
                              ? RideDetailRouteMap(
                                  points: points,
                                  padding: EdgeInsets.only(
                                    top: topInset,
                                    bottom: _sheetOverlap.h,
                                  ),
                                )
                              : _HeroFallback(state: state),
                        ),
                      ),
                    ),
                    // Fades the hero into the plain bar as it collapses.
                    IgnorePointer(
                      child: ColoredBox(
                        color: background.withValues(
                          alpha: 1 - Curves.easeIn.transform(expanded),
                        ),
                      ),
                    ),
                    Positioned(
                      top: topInset,
                      left: 64.w,
                      right: 64.w,
                      height: kToolbarHeight,
                      child: Opacity(
                        opacity: (1 - expanded * 2).clamp(0.0, 1.0),
                        child: Center(
                          child: Text(
                            'Ride details',
                            style: AppTextStyles.labelLarge(context).copyWith(
                              color: AppColors.text(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Rounded top edge of the content sheet, overlapping the hero.
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(_sheetOverlap.h),
              child: Container(
                height: _sheetOverlap.h,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_sheetOverlap.r),
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.borderDefault(context),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h + bottomInset),
            sliver: SliverList.separated(
              itemCount: children.length,
              itemBuilder: (_, index) => children[index],
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 20.h : 12.h),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background(context),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40.w,
          height: 40.w,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20.w,
            color: AppColors.text(context),
          ),
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({this.state});

  final RideOutcome? state;

  @override
  Widget build(BuildContext context) {
    final color = state?.color ?? AppColors.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: kToolbarHeight / 2),
          child: Container(
            width: 84.w,
            height: 84.w,
            decoration: BoxDecoration(
              color: AppColors.background(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              state?.icon ?? Icons.directions_car_rounded,
              size: 40.w,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
