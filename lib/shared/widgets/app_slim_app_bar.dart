import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Lightweight, flat app bar — no card container, no shadow.
///
/// Use on screens where the heavier [AppAppBar] card style is overkill,
/// such as secondary pages, modals, or simple toolbars.
class AppSlimAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppSlimAppBar({
    super.key,
    this.title,
    this.leadingIcon = Icons.arrow_back_ios_new_rounded,
    this.onLeadingTap,
    this.trailing,
    this.centerTitle = true,
  });

  final String? title;
  final IconData leadingIcon;
  final VoidCallback? onLeadingTap;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      height: preferredSize.height + statusBarHeight,
      padding: EdgeInsets.only(
        top: statusBarHeight,
        left: 16.w,
        right: 16.w,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.isDark(context)
              ? [
                  const Color(0xFF2A2A2A),
                  const Color(0xFF1A1A1A),
                  AppColors.background(context),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F6F0),
                  AppColors.background(context),
                ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (title != null && centerTitle)
            Positioned.fill(
              child: Center(
                child: Text(
                  title!,
                  style: AppTextStyles.headingSmall(context).copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          Row(
            children: [
              if (onLeadingTap != null)
                _SlimIconButton(
                  icon: leadingIcon,
                  onTap: onLeadingTap,
                ),
              if (!centerTitle) ...[
                if (title != null) ...[
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTextStyles.headingSmall(context).copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ] else
                const Expanded(child: SizedBox()),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

class _SlimIconButton extends StatelessWidget {
  const _SlimIconButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 20.w,
        color: AppColors.text(context),
      ),
    );
  }
}
