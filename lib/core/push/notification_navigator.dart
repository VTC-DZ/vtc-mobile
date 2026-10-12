import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/notifications/data/notification_repository.dart';
import '../models/token_payload.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
import '../session/auth_session.dart';
import 'notification_destination.dart';
import 'push_notification_service.dart';

/// Opens the screen a notification tap points to, from a push banner or an
/// inbox tile, as [resolveNotificationDestination] decides.
final class NotificationNavigator {
  NotificationNavigator._();

  static const NotificationRepository _repository = NotificationRepository();

  /// A tapped push: marks its inbox item read when it announces one, then
  /// opens its screen.
  static void openFromPush(Map<String, String> data) {
    final notificationId = data['notificationId'];
    if (notificationId != null && AuthSession.isLoggedIn) {
      unawaited(_markRead(notificationId));
    }
    open(data['eventKey'] ?? '', data);
  }

  /// Opens the screen for [eventKey] in the role the UI is in. Does nothing
  /// while logged out or mid-onboarding, for a target in the other role's
  /// shell, or for a push whose target is already on top.
  static void open(String eventKey, Map<String, String> data) {
    // Only a home route means logged in with onboarding done, and it names
    // the role whose shell the UI is in (it follows AuthSession.lastRole).
    final role = switch (AuthSession.resolveInitialRoute()) {
      RouteNames.passengerHome => ActiveRole.passenger,
      RouteNames.driverHome => ActiveRole.driver,
      _ => null,
    };
    if (role == null) {
      _log('$eventKey ignored: logged out or onboarding');
      return;
    }

    final destination = resolveNotificationDestination(
      eventKey: eventKey,
      data: data,
      role: role,
    );
    _log('$eventKey → ${destination?.path ?? 'nowhere'}');
    if (destination == null) return;

    final router = AppRouter.router;
    if (destination.replace) {
      router.go(destination.path, extra: destination.extra);
    } else if (router.state.matchedLocation != destination.path) {
      unawaited(router.push(destination.path, extra: destination.extra));
    }
  }

  /// Signals the inbox only once the server has the read, so the refetched
  /// count already leaves this item out. A failure, such as a 404 for an item
  /// that is gone, refreshes too, which brings the view back in line.
  static Future<void> _markRead(String id) async {
    try {
      await _repository.markRead(id);
    } catch (e) {
      _log('markRead failed: $e');
    }
    PushNotificationService.notifyInboxChanged();
  }

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[NotificationNavigator] $msg');
  }
}
