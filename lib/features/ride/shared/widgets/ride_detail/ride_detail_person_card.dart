import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../ride_identity.dart';
import 'ride_detail_section.dart';

/// The other side of a past ride — the driver (with their vehicle) for a
/// passenger, the passenger for a driver — with a call button when their
/// phone number is known.
class RideDetailPersonCard extends StatelessWidget {
  const RideDetailPersonCard({
    super.key,
    required this.role,
    required this.name,
    this.phone,
    this.vehicleModel,
    this.vehiclePlate,
  });

  /// Caption above the name, e.g. `Your driver`.
  final String role;
  final String name;
  final String? phone;
  final String? vehicleModel;
  final String? vehiclePlate;

  Future<void> _call(String number) async {
    try {
      final launched = await launchUrl(Uri(scheme: 'tel', path: number));
      if (!launched) AppToast.error("Couldn't start the call.");
    } catch (_) {
      AppToast.error("Couldn't start the call.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = phone?.trim() ?? '';
    final model = vehicleModel?.trim() ?? '';
    final plate = vehiclePlate?.trim() ?? '';

    return RideDetailSection(
      child: Row(
        children: [
          InitialsAvatar(name: name, size: 52),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge(context).copyWith(
                    color: AppColors.text(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
                if (model.isNotEmpty || plate.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      if (model.isNotEmpty)
                        Flexible(
                          child: Text(
                            model,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      if (model.isNotEmpty && plate.isNotEmpty)
                        SizedBox(width: 8.w),
                      if (plate.isNotEmpty) VehiclePlateChip(plate: plate),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (number.isNotEmpty) ...[
            SizedBox(width: 10.w),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _call(number),
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Icon(
                    Icons.phone_rounded,
                    size: 20.w,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
