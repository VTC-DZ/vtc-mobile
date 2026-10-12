import '../../../core/constants/me_api_constants.dart';
import '../../../core/models/page_response.dart';
import '../../../core/network/dio_client.dart';
import 'models/app_notification.dart';
import 'models/push_platform.dart';

/// The push token and the notification inbox under `/api/me`. The inbox
/// follows the JWT's `activeRole`: there is no role parameter.
///
/// Not `final`, so tests can extend it with a fake.
class NotificationRepository {
  const NotificationRepository();

  /// One token per user: each call overwrites the stored one.
  Future<void> registerPushToken({
    required String token,
    required PushPlatform platform,
  }) async {
    await DioClient.post(
      path: MeApiConstants.pushToken,
      data: {'token': token, 'platform': platform.wireName},
    );
  }

  /// Newest first: the current role's items plus account items.
  Future<PageResponse<AppNotification>> list({
    int page = 0,
    int size = 20,
  }) async {
    final response = await DioClient.get(
      path: MeApiConstants.notifications,
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data as Map<String, dynamic>,
      AppNotification.fromJson,
    );
  }

  Future<int> unreadCount() async {
    final response =
        await DioClient.get(path: MeApiConstants.notificationsUnreadCount);
    final json = response.data as Map<String, dynamic>;
    return (json['count'] as num?)?.toInt() ?? 0;
  }

  /// Idempotent; returns `204`. A `404` (`NOTIFICATION_NOT_FOUND`) means the
  /// item is gone or isn't the user's.
  Future<void> markRead(String id) async {
    await DioClient.post(
      path: MeApiConstants.notificationRead(id),
      data: <String, dynamic>{},
    );
  }

  /// Marks the current role's inbox read, account items included, and returns
  /// how many items changed.
  Future<int> markAllRead() async {
    final response = await DioClient.post(
      path: MeApiConstants.notificationsReadAll,
      data: <String, dynamic>{},
    );
    final json = response.data as Map<String, dynamic>;
    return (json['updated'] as num?)?.toInt() ?? 0;
  }
}
