import '../../../../core/utils/string_map.dart';

/// An item of the notification inbox (`GET /api/me/notifications`).
///
/// `title` and `body` arrive already rendered in the user's language, so the
/// app shows them as-is. `eventKey` + `data` pick the icon and the screen a
/// tap opens.
final class AppNotification {
  const AppNotification({
    required this.id,
    required this.eventKey,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
    this.readAt,
  });

  final String id;

  /// Stable event identity to switch on, e.g. `wallet.topup_approved`.
  final String eventKey;
  final String title;
  final String body;

  /// Flat deep-link map (`rideId`, `topUpId`, `screen`, …).
  final Map<String, String> data;
  final bool read;
  final String createdAt;
  final String? readAt;

  /// For the optimistic mark-read. The next refetch brings the server's
  /// `readAt`.
  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        eventKey: eventKey,
        title: title,
        body: body,
        data: data,
        read: read ?? this.read,
        createdAt: createdAt,
        readAt: readAt,
      );

  /// A row without an `id` throws, so `PageResponse.fromJson` drops it: it
  /// could never be marked read.
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        eventKey: json['eventKey'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        data: asStringMap(json['data']),
        read: json['read'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '',
        readAt: json['readAt'] as String?,
      );
}
