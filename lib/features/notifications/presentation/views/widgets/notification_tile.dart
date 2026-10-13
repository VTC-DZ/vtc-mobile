import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../data/models/app_notification.dart';
import '../../../utils/notification_time_formatter.dart';

/// One inbox item. The server already renders `title` and `body` in the
/// user's language, so they show as-is. Unread items stand out with a bolder
/// title, a primary dot and a light primary tint.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, this.onTap});

  final AppNotification notification;

  /// Marks the item read and opens its screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      // Material rather than a decorated Container, so the ripple shows on
      // top of the tile's colour.
      child: Material(
        color: unread
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surface(context),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(
            color: unread
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.borderDefault(context),
            width: 1.w,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    _iconFor(notification.eventKey),
                    size: 19.w,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(notification: notification, unread: unread),
                      if (notification.body.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          notification.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: unread
                                ? AppColors.text(context)
                                : AppColors.textSecondary(context),
                          ),
                        ),
                      ],
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

  /// Keyed by the event family, the part of `eventKey` before the first dot.
  static IconData _iconFor(String eventKey) =>
      switch (eventKey.split('.').first) {
        'ride' => Icons.directions_car_rounded,
        'wallet' => Icons.account_balance_wallet_rounded,
        'kyc' || 'driver' => Icons.verified_rounded,
        'user' => Icons.shield_rounded,
        _ => Icons.notifications_rounded,
      };
}

/// Title · relative time · unread dot, with the time on the title's first
/// line.
class _Header extends StatelessWidget {
  const _Header({required this.notification, required this.unread});

  final AppNotification notification;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            notification.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium(context).copyWith(
              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        // Its own row so the dot centres on the time while the time keeps
        // the title's baseline.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatNotificationTime(notification.createdAt),
              style: AppTextStyles.labelSmall(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            if (unread) ...[
              SizedBox(width: 6.w),
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
