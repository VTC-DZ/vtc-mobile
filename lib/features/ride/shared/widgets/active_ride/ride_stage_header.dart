import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/map_geo.dart';
import '../../presentation/cubit/ride_route_cubit/ride_route_cubit.dart';
import '../../presentation/cubit/ride_route_cubit/ride_route_state.dart';

/// Amber for the "arrived / waiting" stage — no app-wide warning token.
const Color rideStageArrivedColor = Color(0xFFF59E0B);

/// Blue for the "on the trip" stage.
const Color rideStageInTripColor = Color(0xFF3B82F6);

/// Top of the active-ride sheet: a live dot and the stage [title], a
/// [subtitle] line prefixed with the remaining road distance of the leg being
/// driven (from the ambient [RideRouteCubit]), and a three-step progress bar
/// (Accepted → Arrived → On trip).
class RideStageHeader extends StatelessWidget {
  const RideStageHeader({
    super.key,
    required this.title,
    required this.color,
    required this.step,
    this.subtitle,
    this.distanceSuffix,
    this.trailing,
  });

  final String title;
  final Color color;

  /// Reached step: 0 accepted, 1 arrived, 2 on trip.
  final int step;

  /// Secondary line, e.g. the address being driven to.
  final String? subtitle;

  /// When set, the remaining leg distance is shown before [subtitle] as
  /// `1.8 km <distanceSuffix>` (e.g. `away`, `to drop-off`).
  final String? distanceSuffix;

  /// Right-aligned slot beside the title (a countdown, a button…).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LiveDot(color: color),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingSmall(context).copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: 8.w),
              trailing!,
            ],
          ],
        ),
        SizedBox(height: 4.h),
        Padding(
          padding: EdgeInsets.only(left: 22.w),
          child: distanceSuffix == null
              ? _Subtitle(text: subtitle)
              : BlocSelector<RideRouteCubit, RideRouteState, List<LatLng>?>(
                  selector: (route) => route.activeLeg,
                  builder: (context, leg) {
                    final distance = leg == null
                        ? null
                        : '${_formatDistance(MapGeo.pathLengthMeters(leg))} '
                            '$distanceSuffix';
                    return _Subtitle(
                      text: [distance, subtitle]
                          .whereType<String>()
                          .where((part) => part.isNotEmpty)
                          .join(' · '),
                      emphasis: distance,
                    );
                  },
                ),
        ),
        SizedBox(height: 14.h),
        _StageProgress(step: step, color: color),
      ],
    );
  }

  static String _formatDistance(double meters) => meters < 1000
      ? '${(meters / 10).round() * 10} m'
      : '${(meters / 1000).toStringAsFixed(1)} km';
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({this.text, this.emphasis});

  final String? text;

  /// Leading part of [text] drawn bold.
  final String? emphasis;

  @override
  Widget build(BuildContext context) {
    final value = text ?? '';
    if (value.isEmpty) return const SizedBox.shrink();
    final style = AppTextStyles.bodySmall(context).copyWith(
      color: AppColors.textSecondary(context),
    );
    final bold = emphasis;
    return Text.rich(
      bold != null && value.startsWith(bold)
          ? TextSpan(
              children: [
                TextSpan(
                  text: bold,
                  style: style.copyWith(
                    color: AppColors.text(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: value.substring(bold.length)),
              ],
            )
          : TextSpan(text: value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

/// Dot with a slowly pulsing halo — the ride is live.
class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 12.w;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size * (1 + t * 1.2),
                height: size * (1 + t * 1.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.35 * (1 - t)),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _StageProgress extends StatelessWidget {
  const _StageProgress({required this.step, required this.color});

  final int step;
  final Color color;

  static const _labels = ['Accepted', 'Arrived', 'On trip'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0) SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5.h,
                  decoration: BoxDecoration(
                    color:
                        i <= step ? color : AppColors.borderDefault(context),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _labels[i],
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: i <= step
                        ? AppColors.text(context)
                        : AppColors.textSecondary(context),
                    fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
