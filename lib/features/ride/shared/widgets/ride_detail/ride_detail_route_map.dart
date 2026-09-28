import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../ride_map_style.dart';

/// Static, non-interactive map of a finished ride's travelled path, with
/// pickup/drop-off pins at its ends. Needs at least two [points].
class RideDetailRouteMap extends StatefulWidget {
  const RideDetailRouteMap({super.key, required this.points});

  final List<LatLng> points;

  @override
  State<RideDetailRouteMap> createState() => _RideDetailRouteMapState();
}

class _RideDetailRouteMapState extends State<RideDetailRouteMap> {
  GoogleMapController? _controller;
  RideMapIcons? _icons;

  @override
  void initState() {
    super.initState();
    RideMapIcons.load().then((icons) {
      if (mounted) setState(() => _icons = icons);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icons = _icons;
    final points = widget.points;

    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault(context), width: 1.w),
      ),
      clipBehavior: Clip.antiAlias,
      // A snapshot, not a navigable map: taps and drags go to the page.
      child: IgnorePointer(
        child: GoogleMap(
          onMapCreated: (controller) {
            _controller = controller;
            RideMapStyle.fitCamera(controller, points);
          },
          initialCameraPosition: CameraPosition(target: points.first, zoom: 13),
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          scrollGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: false,
          polylines: RideMapStyle.polylines(
            RideMapLegs(approach: null, trip: points),
            tripStarted: true,
          ),
          markers: {
            if (icons != null) ...{
              Marker(
                markerId: const MarkerId('pickup'),
                position: points.first,
                icon: icons.pickup.descriptor,
                anchor: icons.pickup.anchor,
              ),
              Marker(
                markerId: const MarkerId('dropoff'),
                position: points.last,
                icon: icons.dropoff.descriptor,
                anchor: icons.dropoff.anchor,
              ),
            },
          },
        ),
      ),
    );
  }
}
