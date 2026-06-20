import 'dart:convert';

import 'driver_ride_models.dart';

/// The driver-side socket `type` values this layer handles, mapped to their wire
/// names. Any other `type` has no entry here and is ignored.
enum RideSocketEventType {
  rideBroadcast('ride.broadcast'),
  rideBroadcastCancelled('ride.broadcast_cancelled');

  const RideSocketEventType(this.wireName);

  /// The on-the-wire `type` string in the socket envelope.
  final String wireName;

  /// Resolves a wire `type` to its enum value, or `null` when unrecognised.
  static RideSocketEventType? fromWire(String value) {
    for (final type in values) {
      if (type.wireName == value) return type;
    }
    return null;
  }
}

/// Typed driver-side events decoded from the raw socket [String] frames exposed
/// by `RideSocketService.frameStream`.
///
/// This is the "decode the envelope" seam the socket service documents: it reads
/// the `{ type, payload, timestamp }` envelope and turns the broadcast events
/// into typed values that [AvailableRidesCubit] applies to its list. Only the two
/// broadcast events are modelled for now (see `swagger/epic-03-ride.md` §5/§9);
/// every other `type` parses to `null` and is ignored.
sealed class RideSocketEvent {
  const RideSocketEvent();

  /// Decodes a raw socket frame into a [RideSocketEvent], or `null` when the
  /// frame is malformed or carries a `type` we do not handle here. Socket frames
  /// are best-effort, so a bad frame is swallowed rather than thrown.
  static RideSocketEvent? tryParse(String frame) {
    try {
      final envelope = jsonDecode(frame) as Map<String, dynamic>;
      final type = RideSocketEventType.fromWire(envelope['type'] as String? ?? '');
      final payload = envelope['payload'] as Map<String, dynamic>?;
      if (type == null || payload == null) return null;

      switch (type) {
        case RideSocketEventType.rideBroadcast:
          return RideBroadcast(AvailableRequestCard.fromJson(payload));
        case RideSocketEventType.rideBroadcastCancelled:
          return RideBroadcastCancelled(
            rideRequestId: payload['rideRequestId'] as String,
            reason: payload['reason'] as String? ?? '',
          );
      }
    } catch (_) {
      return null;
    }
  }
}

/// A request matched this driver and should be upserted into the available list.
/// May arrive repeatedly for the same `rideRequestId` — dedupe by that id.
final class RideBroadcast extends RideSocketEvent {
  const RideBroadcast(this.request);

  final AvailableRequestCard request;
}

/// A previously broadcast request is gone and its card should be removed.
final class RideBroadcastCancelled extends RideSocketEvent {
  const RideBroadcastCancelled({
    required this.rideRequestId,
    required this.reason,
  });

  final String rideRequestId;
  final String reason;
}
