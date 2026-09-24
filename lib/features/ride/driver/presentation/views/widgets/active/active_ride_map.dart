import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/utils/map_gestures.dart';
import '../../../../../../../core/utils/map_marker_factory.dart';
import '../../../../../../../core/widgets/app_toast.dart';
import '../../../../data/models/driver_ride_models.dart';
import '../../../../../passenger/presentation/views/widgets/location/map_button.dart';

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
  GoogleMapController? _mapController;
  BitmapDescriptor _pickupIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _dropoffIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _driverIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final icons = await Future.wait([
      MapMarkerFactory.circle(
        color: AppColors.primary,
        icon: Icons.trip_origin_rounded,
        glow: true,
      ),
      MapMarkerFactory.circle(
        color: AppColors.error,
        icon: Icons.location_on_rounded,
      ),
      MapMarkerFactory.circle(
        color: Colors.blue.shade700,
        icon: Icons.directions_car_rounded,
        glow: true,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _pickupIcon = icons[0];
      _dropoffIcon = icons[1];
      _driverIcon = icons[2];
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Recenters the camera on the driver's own live GPS position (already
  /// streamed by the parent view). Keeps the current zoom level.
  void _goToDriverLocation() {
    final position = widget.driverPosition;
    if (position == null) {
      AppToast.error('Locating your position, please wait.');
      return;
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  void _zoomIn() => _mapController?.animateCamera(CameraUpdate.zoomIn());

  void _zoomOut() => _mapController?.animateCamera(CameraUpdate.zoomOut());

  @override
  Widget build(BuildContext context) {
    final pickupPoint = LatLng(widget.ride.pickup.lat, widget.ride.pickup.lng);
    final dropoffPoint =
        LatLng(widget.ride.dropoff.lat, widget.ride.dropoff.lng);
    const center = Offset(0.5, 0.5);

    return Stack(
      children: [
        GoogleMap(
          gestureRecognizers: mapGestureRecognizers,
          onMapCreated: (controller) => _mapController = controller,
          // Center on the passenger (pickup) when the active ride opens, so
          // the driver immediately sees where to pick them up.
          initialCameraPosition: CameraPosition(target: pickupPoint, zoom: 15),
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('pickup'),
              position: pickupPoint,
              icon: _pickupIcon,
              anchor: center,
            ),
            Marker(
              markerId: const MarkerId('dropoff'),
              position: dropoffPoint,
              icon: _dropoffIcon,
              anchor: center,
            ),
            // Driver's own GPS position
            if (widget.driverPosition != null)
              Marker(
                markerId: const MarkerId('driver'),
                position: LatLng(
                  widget.driverPosition!.latitude,
                  widget.driverPosition!.longitude,
                ),
                icon: _driverIcon,
                anchor: center,
                zIndexInt: 1,
              ),
          },
        ),

        // Map controls: current location + zoom in/out (top-right)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8.h,
          right: 16.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapButton(
                icon: Icons.my_location_rounded,
                onTap: _goToDriverLocation,
              ),
              SizedBox(height: 12.h),
              MapButton(
                icon: Icons.add_rounded,
                onTap: _zoomIn,
              ),
              SizedBox(height: 12.h),
              MapButton(
                icon: Icons.remove_rounded,
                onTap: _zoomOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
