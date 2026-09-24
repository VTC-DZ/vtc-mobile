import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/map_gestures.dart';
import '../../../../../../../core/utils/map_marker_factory.dart';
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
  GoogleMapController? _mapController;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _ownIcon;
  String? _driverIconLabel;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final driverLabel = widget.driverLabel ?? 'Driver';
    final icons = await Future.wait([
      MapMarkerFactory.labeled(
        color: AppColors.primary,
        icon: Icons.trip_origin_rounded,
        label: 'Pickup',
        glow: true,
      ),
      MapMarkerFactory.labeled(
        color: AppColors.error,
        icon: Icons.location_on_rounded,
        label: 'Dropoff',
      ),
      MapMarkerFactory.labeled(
        color: AppColors.primary,
        icon: Icons.directions_car_rounded,
        label: driverLabel,
        glow: true,
      ),
      MapMarkerFactory.circle(
        color: AppColors.white,
        icon: Icons.person_rounded,
        iconSize: 14,
        padding: 4,
        iconColor: AppColors.primary,
        borderColor: AppColors.primary,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _pickupIcon = icons[0];
      _dropoffIcon = icons[1];
      _driverIcon = icons[2];
      _ownIcon = icons[3];
      _driverIconLabel = driverLabel;
    });
  }

  @override
  void didUpdateWidget(LiveMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.driverLabel ?? 'Driver') != _driverIconLabel &&
        _driverIconLabel != null) {
      _loadIcons();
    }
    final lat = widget.driverLat;
    final lng = widget.driverLng;
    if (lat != null &&
        lng != null &&
        oldWidget.driverLat != null &&
        oldWidget.driverLng != null &&
        (oldWidget.driverLat != lat || oldWidget.driverLng != lng)) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
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
    const bottomAnchor = Offset(0.5, 1);
    return Stack(
      children: [
        GoogleMap(
          gestureRecognizers: mapGestureRecognizers,
          // setState so _MapZoomButtons receives the controller.
          onMapCreated: (controller) =>
              setState(() => _mapController = controller),
          initialCameraPosition: CameraPosition(target: driverPoint, zoom: 14),
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          markers: {
            // Pickup point
            if (widget.pickup != null)
              Marker(
                markerId: const MarkerId('pickup'),
                position: LatLng(widget.pickup!.lat, widget.pickup!.lng),
                icon: _pickupIcon ?? BitmapDescriptor.defaultMarker,
                anchor: bottomAnchor,
              ),
            // Dropoff point
            if (widget.dropoff != null)
              Marker(
                markerId: const MarkerId('dropoff'),
                position: LatLng(widget.dropoff!.lat, widget.dropoff!.lng),
                icon: _dropoffIcon ?? BitmapDescriptor.defaultMarker,
                anchor: bottomAnchor,
              ),
            // Driver's live position
            Marker(
              markerId: const MarkerId('driver'),
              position: driverPoint,
              icon: _driverIcon ?? BitmapDescriptor.defaultMarker,
              anchor: bottomAnchor,
              zIndexInt: 2,
            ),
            // Passenger's own position ("you")
            if (widget.ownPosition != null)
              Marker(
                markerId: const MarkerId('own'),
                position: LatLng(
                  widget.ownPosition!.latitude,
                  widget.ownPosition!.longitude,
                ),
                icon: _ownIcon ?? BitmapDescriptor.defaultMarker,
                anchor: const Offset(0.5, 0.5),
                zIndexInt: 1,
              ),
          },
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

class _MapZoomButtons extends StatelessWidget {
  const _MapZoomButtons({required this.controller});

  final GoogleMapController? controller;

  void _zoom(double delta) {
    controller?.animateCamera(CameraUpdate.zoomBy(delta));
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
