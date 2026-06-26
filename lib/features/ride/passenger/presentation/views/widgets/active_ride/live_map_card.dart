import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

class LiveMapCard extends StatefulWidget {
  const LiveMapCard({
    super.key,
    required this.driverLat,
    required this.driverLng,
    required this.ownPosition,
  });

  final double? driverLat;
  final double? driverLng;
  final Position? ownPosition;

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
    // Only animate when the map was already on screen (old coords non-null).
    // If old coords were null we were showing the placeholder — FlutterMap
    // hasn't rendered yet, so calling move() would throw.
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
      return Container(
        height: 250.h,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderDefault(context)),
        ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: 250.h,
        child: FlutterMap(
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
                Marker(
                  point: driverPoint,
                  child: const Icon(Icons.directions_car,
                      color: Colors.blue, size: 32),
                ),
                if (widget.ownPosition != null)
                  Marker(
                    point: LatLng(
                      widget.ownPosition!.latitude,
                      widget.ownPosition!.longitude,
                    ),
                    child: const Icon(Icons.person_pin_circle,
                        color: Colors.green, size: 32),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
