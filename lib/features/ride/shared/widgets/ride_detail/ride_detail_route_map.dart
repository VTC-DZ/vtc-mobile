import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../ride_map_style.dart';

/// Static, non-interactive map of a ride's path, with pickup/drop-off pins at
/// its ends. Fills its parent; needs at least two [points].
class RideDetailRouteMap extends StatefulWidget {
  const RideDetailRouteMap({
    super.key,
    required this.points,
    this.padding = EdgeInsets.zero,
  });

  final List<LatLng> points;

  /// Map padding, keeping the framed route clear of overlaid UI.
  final EdgeInsets padding;

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
  void didUpdateWidget(RideDetailRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // e.g. a straight-line fallback replaced by the road route.
    final controller = _controller;
    if (controller != null && widget.points != oldWidget.points) {
      RideMapStyle.fitCamera(controller, widget.points);
    }
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

    // A snapshot, not a navigable map: taps and drags go to the page.
    return IgnorePointer(
      child: GoogleMap(
        onMapCreated: (controller) {
          _controller = controller;
          RideMapStyle.fitCamera(controller, points);
        },
        initialCameraPosition: CameraPosition(target: points.first, zoom: 13),
        padding: widget.padding,
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
    );
  }
}
