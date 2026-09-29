import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/driver_api_constants.dart';
import '../models/token_payload.dart';
import 'dio_client.dart';
import 'ride_socket_service.dart';

/// Sends the driver's GPS position every 15s while armed: as a WS
/// `driver.location` envelope while the driver socket is connected, and via
/// REST `POST /api/driver/location` (same payload) while it is down, so the
/// matching engine never works off a stale position across reconnect/backoff
/// cycles or a failed socket.
///
/// Armed by [DriverAvailabilityCubit] on go-online and disarmed on
/// go-offline, role switch, logout and forced re-login — so the REST fallback
/// can only fire for an online driver session. Implemented as a static
/// singleton to match [RideSocketService].
///
/// See `swagger/epic-03-ride.md` §7/§9/§11.
final class DriverLocationStreamer {
  DriverLocationStreamer._();

  static const Duration _interval = Duration(seconds: 15);

  static StreamSubscription<RideSocketStatus>? _statusSub;
  static Timer? _timer;
  static bool _armed = false;
  static bool _ticking = false;
  static RideSocketStatus? _lastStatus;

  /// Arms the streamer and sends a first position straight away. Idempotent.
  static void start() {
    if (_armed) return;
    _armed = true;
    _lastStatus = RideSocketService.status;
    _statusSub ??= RideSocketService.statusStream.listen(_onStatus);
    unawaited(_tick());
    _timer ??= Timer.periodic(_interval, (_) => _tick());
  }

  /// Disarms the streamer and stops the timer. Idempotent.
  static void stop() {
    _armed = false;
    _statusSub?.cancel();
    _statusSub = null;
    _timer?.cancel();
    _timer = null;
  }

  /// Disarms the streamer and disconnects the driver socket together.
  /// Idempotent — safe to call even if neither was running.
  static Future<void> stopAndDisconnect() async {
    stop();
    await RideSocketService.disconnect();
  }

  // The timer keeps running whatever the socket does; this only pushes a fresh
  // position over WS the moment the socket comes back, instead of waiting up
  // to a full interval.
  static void _onStatus(RideSocketStatus status) {
    final reconnected = status == RideSocketStatus.connected &&
        _lastStatus != RideSocketStatus.connected;
    _lastStatus = status;
    if (_armed && reconnected) unawaited(_tick());
  }

  static Future<void> _tick() async {
    // A reconnect-triggered tick can overlap a timer tick while GPS resolves.
    if (_ticking) return;
    _ticking = true;
    try {
      if (!await _hasLocationPermission()) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      // Disarmed while GPS was resolving — don't send anything.
      if (!_armed) return;

      final payload = {
        'lat': position.latitude,
        'lng': position.longitude,
        'capturedAt': position.timestamp.toUtc().toIso8601String(),
        'accuracyM': position.accuracy,
      };

      // WS is the primary channel. `send` can still return false if the
      // socket died between the status check and the write.
      final socketUp = RideSocketService.status == RideSocketStatus.connected &&
          RideSocketService.activeRole == ActiveRole.driver;
      if (socketUp &&
          RideSocketService.send({
            'type': 'driver.location',
            'payload': payload,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          })) {
        _log('sent driver.location over WS $payload');
        return;
      }

      await DioClient.post(path: DriverApiConstants.location, data: payload);
      _log('socket down — sent location over REST $payload');
    } catch (e) {
      // Best-effort: the next tick retries. The driver stays online either way.
      _log('tick failed: $e');
    } finally {
      _ticking = false;
    }
  }

  /// Same permission flow as `LocationPickerCubit.init()` — request once if
  /// undetermined, otherwise silently skip the tick when denied. No error is
  /// surfaced; the driver stays online/connected regardless.
  static Future<bool> _hasLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[DriverLocationStreamer] $msg');
  }
}
