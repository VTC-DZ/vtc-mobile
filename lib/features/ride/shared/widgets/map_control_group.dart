import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

/// One button inside a [MapControlGroup].
class MapControlAction {
  const MapControlAction({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// When true, a spinner replaces the icon and taps are ignored.
  final bool isLoading;
}

/// Vertical pill of map buttons (fit route, my location, zoom in/out, …)
/// separated by hairline dividers. Shared by every ride map so the controls
/// look the same everywhere.
class MapControlGroup extends StatelessWidget {
  const MapControlGroup({
    super.key,
    required this.actions,
    this.buttonSize = 40,
  });

  final List<MapControlAction> actions;

  /// Side length of each square button, in design pixels (scaled with `.w`).
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10.r);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0)
                  SizedBox(
                    width: buttonSize.w,
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderDefault(context),
                    ),
                  ),
                _MapControlButton(action: actions[i], size: buttonSize),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.action, required this.size});

  final MapControlAction action;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.isLoading ? null : action.onTap,
      child: SizedBox(
        width: size.w,
        height: size.w,
        child: Center(
          child: action.isLoading
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(
                  action.icon,
                  size: (size * 0.5).w,
                  color: AppColors.text(context),
                ),
        ),
      ),
    );
  }
}
