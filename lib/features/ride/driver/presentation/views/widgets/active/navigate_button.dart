import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/external_navigation.dart';
import '../../../../../../../core/widgets/app_toast.dart';
import '../../../../../shared/models/shared_ride_models.dart';

/// Compact pill that opens Google Maps with turn-by-turn directions to
/// [target] (the pickup before the ride starts, the dropoff during it).
class NavigateButton extends StatelessWidget {
  const NavigateButton({super.key, required this.target});

  final CoordinatePoint target;

  Future<void> _navigate() async {
    final opened = await ExternalNavigation.openDirections(
      LatLng(target.lat, target.lng),
    );
    if (!opened) AppToast.error('Could not open Google Maps');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: _navigate,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.navigation_rounded,
                  size: 14.w, color: AppColors.white),
              SizedBox(width: 4.w),
              Text(
                'Navigate',
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
