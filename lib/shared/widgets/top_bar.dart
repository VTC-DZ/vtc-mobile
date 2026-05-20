import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

import 'app_top_bar.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    this.title = 'Where to?',
    this.subtitle = 'Good to see you',
    this.leadingIcon = Icons.menu_rounded,
    this.trailingIcon = Icons.notifications_none_rounded,
    this.onLeadingTap,
    this.onTrailingTap,
  });

  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      onLeadingTap: onLeadingTap ?? () => ZoomDrawer.of(context)?.toggle(),
      onTrailingTap: onTrailingTap,
    );
  }
}
