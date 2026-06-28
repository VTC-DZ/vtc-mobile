import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/models/shared_ride_models.dart';

/// Full-screen capable live map. Sizes to whatever its parent gives it.
/// Caller is responsible for bounding the widget (e.g. Positioned.fill or SizedBox).
class LiveMapCard extends StatefulWidget {
  const LiveMapCard({
    super.key,
    required this.driverLat,
    required this.driverLng,
    required this.ownPosition,
    this.pickup,
    this.dropoff,
    this.driverLabel,
  });

  final double? driverLat;
  final double? driverLng;
  final Position? ownPosition;
  final CoordinatePoint? pickup;
  final CoordinatePoint? dropoff;
  final String? driverLabel;

  @override
  State<LiveMapCard> createState() => _LiveMapCardState();
}

class _LiveMapCardState extends State<LiveMapCard> {
  final _mapController = MapController();

  @override
  void didUpdateWidget(LiveMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lat = widget.driverLat;
    final lng = widget.driverLng;
    if (lat != null &&
        lng != null &&
        oldWidget.driverLat != null &&
        oldWidget.driverLng != null &&
        (oldWidget.driverLat != lat || oldWidget.driverLng != lng)) {
      _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.driverLat;
    final lng = widget.driverLng;

    if (lat == null || lng == null) {
      return ColoredBox(
        color: AppColors.surface(context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_searching,
                  color: AppColors.textSecondary(context), size: 32.w),
              SizedBox(height: 8.h),
              Text(
                'Waiting for driver location…',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final driverPoint = LatLng(lat, lng);
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: driverPoint,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'khfif_drif',
            ),
            MarkerLayer(
              markers: [
                // Pickup point
                if (widget.pickup != null)
                  _labeledMarker(
                    point: LatLng(widget.pickup!.lat, widget.pickup!.lng),
                    color: AppColors.primary,
                    icon: Icons.trip_origin_rounded,
                    label: 'Pickup',
                    glow: true,
                  ),
                // Dropoff point
                if (widget.dropoff != null)
                  _labeledMarker(
                    point: LatLng(widget.dropoff!.lat, widget.dropoff!.lng),
                    color: AppColors.error,
                    icon: Icons.location_on_rounded,
                    label: 'Dropoff',
                  ),
                // Driver's live position
                _labeledMarker(
                  point: driverPoint,
                  color: AppColors.primary,
                  icon: Icons.directions_car_rounded,
                  label: widget.driverLabel ?? 'Driver',
                  glow: true,
                ),
                // Passenger's own position ("you")
                if (widget.ownPosition != null)
                  Marker(
                    point: LatLng(
                      widget.ownPosition!.latitude,
                      widget.ownPosition!.longitude,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.primary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(Icons.person_rounded,
                          color: AppColors.primary, size: 14.w),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 12.w,
          bottom: 150.h,
          child: _MapZoomButtons(controller: _mapController),
        ),
      ],
    );
  }
}

/// A pin (circular icon badge) with a floating [label] chip above it. The pin's
/// bottom sits on the [point] so the chip reads cleanly above the marker.
Marker _labeledMarker({
  required LatLng point,
  required Color color,
  required IconData icon,
  required String label,
  bool glow = false,
}) {
  return Marker(
    point: point,
    width: 120.w,
    height: 64.w,
    alignment: Alignment.bottomCenter,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HintChip(text: label, color: color),
          SizedBox(height: 4.w),
          _PinCircle(color: color, icon: icon, glow: glow),
        ],
      ),
    ),
  );
}

class _PinCircle extends StatelessWidget {
  const _PinCircle({
    required this.color,
    required this.icon,
    this.glow = false,
  });

  final Color color;
  final IconData icon;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: AppColors.white, size: 18.w),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      constraints: BoxConstraints(maxWidth: 100.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSmall(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MapZoomButtons extends StatelessWidget {
  const _MapZoomButtons({required this.controller});

  final MapController controller;

  void _zoom(double delta) {
    controller.move(
      controller.camera.center,
      controller.camera.zoom + delta,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomBtn(
            icon: Icons.add_rounded,
            onTap: () => _zoom(1),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderDefault(context),
          ),
          _ZoomBtn(
            icon: Icons.remove_rounded,
            onTap: () => _zoom(-1),
          ),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40.w,
        height: 40.w,
        child: Icon(icon, size: 20.w, color: AppColors.text(context)),
      ),
    );
  }
}
