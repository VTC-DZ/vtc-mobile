import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hands turn-by-turn navigation off to Google Maps.
abstract final class ExternalNavigation {
  ExternalNavigation._();

  /// Opens Google Maps with driving directions to [destination] — the app
  /// when installed, the browser otherwise. Returns `false` if nothing could
  /// open the link.
  static Future<bool> openDirections(LatLng destination) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${destination.latitude},${destination.longitude}',
      'travelmode': 'driving',
      // Start turn-by-turn right away instead of showing the route overview.
      'dir_action': 'navigate',
    });
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
