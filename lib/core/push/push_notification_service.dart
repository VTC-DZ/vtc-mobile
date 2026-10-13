import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/data/models/push_platform.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../session/auth_session.dart';
import '../theme/app_colors.dart';
import '../utils/string_map.dart';
import 'notification_navigator.dart';

/// Owns FCM and the local-notification plugin: the Android channel, the
/// foreground display policy, the tap entry points and push-token
/// registration.
///
/// Notifications never use the ride socket. The inbox badge stays fresh
/// through [inboxChanges] (a foreground push that announces an inbox item),
/// app resume and REST refetches.
final class PushNotificationService {
  PushNotificationService._();

  /// Must match `default_notification_channel_id` in AndroidManifest.xml, so
  /// pushes the OS shows in the background and the local notifications shown
  /// in the foreground land in the same channel.
  static const String _channelId = 'rapidoo_alerts';
  static const String _channelName = 'Alerts';
  static const String _channelDescription = 'Rides, wallet and account updates';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      color: AppColors.primary,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const int _apnsAttempts = 5;
  static const Duration _apnsRetryDelay = Duration(seconds: 1);
  static const Duration _tokenTimeout = Duration(seconds: 3);

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static const NotificationRepository _repository = NotificationRepository();
  static final StreamController<void> _inboxChanges =
      StreamController<void>.broadcast();

  static String? _token;
  static Future<void>? _registering;

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Emits when the inbox has new content. It replaces the socket's
  /// notification frame, which this app deliberately doesn't use.
  static Stream<void> get inboxChanges => _inboxChanges.stream;

  static void notifyInboxChanged() => _inboxChanges.add(null);

  /// Awaited in `main()` before `runApp`. Never throws: a push failure must
  /// not block startup.
  static Future<void> init() async {
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android:
              AndroidInitializationSettings('@drawable/ic_stat_notification'),
          // These default to true and would prompt on the phone-entry screen.
          // registerDevice() asks after login instead.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _openPayload(response.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      // Otherwise iOS presents every push in the foreground. The local
      // notification presents the inbox ones. A no-op on Android.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) =>
            NotificationNavigator.openFromPush(asStringMap(message.data)),
      );
      _messaging.onTokenRefresh.listen((token) {
        _token = token;
        _log('FCM token refreshed: $token');
        if (AuthSession.isLoggedIn) unawaited(_send(token));
      });
    } catch (e) {
      _log('init failed: $e');
    }
  }

  /// Routes the tap that cold-started the app, if any. Called after `runApp`;
  /// never throws.
  static Future<void> handleLaunchTap() async {
    try {
      final data = await _launchTapData();
      if (data == null) return;
      // Not a bare addPostFrameCallback: the first frame may already be done
      // by now, and a post-frame callback never schedules a frame of its own.
      await WidgetsBinding.instance.endOfFrame;
      NotificationNavigator.openFromPush(data);
    } catch (e) {
      _log('launch tap ignored: $e');
    }
  }

  /// Registers this device's push token. Called after every login, because
  /// the server clears the stored token on login, and on every app start while
  /// logged in. Best-effort and de-duplicated while in flight; never throws.
  ///
  /// No token is a normal outcome. It is the state on iOS until there is an
  /// Apple Developer account, so it is skipped with one debug log.
  static Future<void> registerDevice() =>
      _registering ??= _register().whenComplete(() => _registering = null);

  /// This device's token for the logout body, or `null` when there is none.
  static Future<String?> currentToken() async {
    final cached = _token;
    if (cached != null) return cached;
    try {
      return await _messaging.getToken().timeout(_tokenTimeout);
    } catch (_) {
      return null;
    }
  }

  /// Removes every notification this app is showing. Used on logout.
  static Future<void> clearDisplayed() async {
    try {
      await _local.cancelAll();
    } catch (e) {
      _log('clear failed: $e');
    }
  }

  static Future<void> _register() async {
    try {
      // Also the Android 13+ POST_NOTIFICATIONS prompt. A denial doesn't stop
      // registration: pushes start working if the user allows them later.
      final settings = await _messaging.requestPermission();
      _log('permission: ${settings.authorizationStatus.name}');

      // Until APNs answers, getToken() fails with apns-token-not-set.
      if (Platform.isIOS && !await _apnsTokenReady()) {
        _log('no APNs token, registration skipped');
        return;
      }
      final token = await _messaging.getToken();
      if (token == null) {
        _log('no FCM token, registration skipped');
        return;
      }
      _token = token;
      _log('FCM token: $token');
      await _send(token);
    } catch (e) {
      _log('registration skipped: $e');
    }
  }

  static Future<bool> _apnsTokenReady() async {
    for (var attempt = 0; attempt < _apnsAttempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(_apnsRetryDelay);
      if (await _messaging.getAPNSToken() != null) return true;
    }
    return false;
  }

  static Future<void> _send(String token) async {
    try {
      await _repository.registerPushToken(
        token: token,
        platform: Platform.isIOS ? PushPlatform.ios : PushPlatform.android,
      );
    } catch (e) {
      _log('token not registered: $e');
    }
  }

  /// The foreground mirrors the background: every push with a title and body
  /// is shown as a heads-up banner. One that announces an inbox item also
  /// refreshes the badge.
  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = asStringMap(message.data);
    _log('foreground push: ${data['eventKey'] ?? message.messageId}');
    if (data['notificationId'] != null) notifyInboxChanged();

    final notification = message.notification;
    if (notification == null) return;
    try {
      await _local.show(
        id: _localId(message, data),
        title: notification.title,
        body: notification.body,
        notificationDetails: _details,
        payload: jsonEncode(data),
      );
    } catch (e) {
      _log('show failed: $e');
    }
  }

  /// Stable per subject, so a re-push replaces its banner instead of stacking
  /// a second one: the inbox item, or for offers the ride request, as the
  /// server's `offer:<rideRequestId>` collapse key does in the background.
  /// Not [RemoteMessage.collapseKey]: Android can report the package name
  /// there when the server sets none, which would merge every banner.
  static int _localId(RemoteMessage message, Map<String, String> data) {
    final rideRequestId = data['rideRequestId'];
    final key = data['notificationId'] ??
        (data['eventKey'] == 'offer.created' && rideRequestId != null
            ? 'offer:$rideRequestId'
            : message.messageId);
    return (key ?? '').hashCode & 0x7fffffff;
  }

  static Future<Map<String, String>?> _launchTapData() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) return asStringMap(message.data);

    final launch = await _local.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch == null || !launch.didNotificationLaunchApp || payload == null) {
      return null;
    }
    return asStringMap(jsonDecode(payload));
  }

  static void _openPayload(String? payload) {
    if (payload == null) return;
    try {
      NotificationNavigator.openFromPush(asStringMap(jsonDecode(payload)));
    } catch (e) {
      _log('tap ignored: $e');
    }
  }

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[Push] $msg');
  }
}
