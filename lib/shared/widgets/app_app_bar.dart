// lib/shared/widgets/app_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_top_bar.dart';

/// App-wide [AppBar] that blends with the scaffold background.
///
/// [title] is displayed centered. [onLeadingTap] shows a leading back icon.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.onLeadingTap,
  });

  final String? title;
  final String? subtitle;
  final VoidCallback? onLeadingTap;

  @override
  Size get preferredSize => Size.fromHeight(92.h);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: AppTopBar(
        title: title ?? '',
        subtitle: subtitle,
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingTap: onLeadingTap,
      ),
    );
  }
}
