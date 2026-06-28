import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../data/models/driver_ride_models.dart';

/// Full-screen live map for the driver's active ride. Shows pickup and dropoff
/// markers plus the driver's own GPS position (when available), with built-in
/// zoom controls.
class ActiveRideMap extends StatefulWidget {
  const ActiveRideMap({
    super.key,
    required this.ride,
    required this.driverPosition,
  });

  final ActiveDriverRideResponse ride;
  final Position? driverPosition;

  @override
  State<ActiveRideMap> createState() => _ActiveRideMapState();
}

class _ActiveRideMapState extends State<ActiveRideMap> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickupPoint = LatLng(widget.ride.pickup.lat, widget.ride.pickup.lng);
    final dropoffPoint =
        LatLng(widget.ride.dropoff.lat, widget.ride.dropoff.lng);
    final centerLat =
        (widget.ride.pickup.lat + widget.ride.dropoff.lat) / 2;
    final centerLng =
        (widget.ride.pickup.lng + widget.ride.dropoff.lng) / 2;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(centerLat, centerLng),
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'khfif_drif',
            ),
            MarkerLayer(
              markers: [
                // Pickup marker
                Marker(
                  point: pickupPoint,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.trip_origin_rounded,
                        color: AppColors.white, size: 16.w),
                  ),
                ),
                // Dropoff marker
                Marker(
                  point: dropoffPoint,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on_rounded,
                        color: AppColors.white, size: 16.w),
                  ),
                ),
                // Driver's own GPS position
                if (widget.driverPosition != null)
                  Marker(
                    point: LatLng(
                      widget.driverPosition!.latitude,
                      widget.driverPosition!.longitude,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(Icons.directions_car_rounded,
                          color: AppColors.white, size: 16.w),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Zoom controls
        Positioned(
          right: 12.w,
          bottom: 150.h,
          child: _MapZoomButtons(controller: _mapController),
        ),
      ],
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
          _ZoomBtn(icon: Icons.add_rounded, onTap: () => _zoom(1)),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderDefault(context),
          ),
          _ZoomBtn(icon: Icons.remove_rounded, onTap: () => _zoom(-1)),
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
