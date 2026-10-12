# Notifications (Push + Inbox): Implementation Progress

**Status:** 🟡 In progress. Phases 0 to 4 are done. The iOS push token is expected to be missing until there is an Apple Developer account.

**Spec:**
- [Untitled.md](Untitled.md), the backend handoff of Oct 10, 2026.
- [swagger/account.json](swagger/account.json): the `/api/me/push-token` and `/api/me/notifications` endpoints, and the `LogoutRequest` body.
- The backend repo `vtc-backend` (local checkout `../VTC/vtc-backend`, `master` @ `79acd27`):
  - `docs/api/account.md`, sections Push Token and Notifications
  - `docs/modules/06-notification.md`
  - `vtc-app/.../notification/service/FcmPushAdapter.java`

**Legend:** `[x]` done · `[ ]` pending

---

## Overview

The backend stores notifications and delivers them in three ways: an FCM push to the phone, a REST inbox (list, unread count, mark read), and a `notification.created` WebSocket frame.

> **No WebSocket for notifications.** Notifications use FCM push and the REST inbox only.
> - Do not handle `notification.created`.
> - Do not add a notification event to `RideSocketEventType`.
> - Do not import `RideSocketService` (or its `frameStream` / `statusStream`) from any notification code.
>
> The badge stays fresh through the foreground FCM message, app resume, and REST refetches.

What exists today:
- `firebase_core` is initialised in [main.dart](lib/main.dart) (commit `f0423ea`), with `google-services.json` and `GoogleService-Info.plist` for the Firebase project `rapido-1956d`.
- Nothing else: no messaging plugin, no permission prompt, no token registration, no inbox screen.
- The bell on the home top bars ([top_bar.dart](lib/shared/widgets/top_bar.dart)) has no tap handler, and its dot is hard-coded on ([app_top_bar.dart:97](lib/shared/widgets/app_top_bar.dart#L97)).

Rules that shape the client:

- **The inbox is the truth.** A push can be missed: there may be no token, the permission may be off, the user may be capped, or the push may have expired. So refetch the unread count and the list when a home shell opens, when the app resumes, and on pull-to-refresh.
- **Text arrives ready.** The server renders `title` and `body` in the user's language (fr / ar). The app translates nothing.
- **Register the push token after every login.** The server clears the stored token on login, and on logout too.
- **Not every push is in the inbox.** These are listed: ride completed or cancelled, wallet movements, KYC and account decisions. Trip progress, new ride requests and offers are **push only**, and they expire after 120 s.
- **`eventKey` + `data`** on every push and inbox item pick the icon and the screen to open.
- **The inbox follows the JWT `activeRole`.** There is no role parameter; the user switches role to see the other inbox. Account items (`user.*`) show in both.

---

## Backend contract

### REST: `/api/me` (account chain, PASSENGER or DRIVER JWT)

| Method | Path | Body / query | Returns | Notes |
|---|---|---|---|---|
| `POST` | `/api/me/push-token` | `{ token, platform: IOS \| ANDROID }` | `200 { registered: true }` | One token per user; each call overwrites it. |
| `DELETE` | `/api/me/push-token?token=` | — | `204` | Opt-out, compare-and-clear when `token` is given. *Not used in v1 (no settings toggle).* |
| `GET` | `/api/me/notifications` | `unreadOnly` (false), `page` (0), `size` (20, clamped 1..100) | `PageResponse<Notification>` | Newest first: the current role's items plus account items. |
| `GET` | `/api/me/notifications/unread-count` | — | `{ count }` | |
| `POST` | `/api/me/notifications/{id}/read` | — | `204` | Idempotent. Keyed by user, not by role. |
| `POST` | `/api/me/notifications/read-all` | — | `{ updated }` | The current role's inbox, account items included. |
| `POST` | `/api/auth/logout` | `{ pushToken }` (optional) | `204` | **Send it.** The server then clears the stored token only if it matches, so a late logout from an old phone can't unregister the new one. |

**Models**

- `Notification`: `id`, `eventKey`, `title`, `body`, `data`, `read`, `createdAt`, `readAt?`. `data` is a flat `string → string` map.
- `PageResponse<T>`: `{ data, page, size, totalElements, totalPages }`. Reuse [page_response.dart](lib/core/models/page_response.dart).

### Token lifecycle (server side)

The server clears the stored token on:
- **Login** (OTP verify), because a login replaces the user's one session.
- **Logout.**
- `DELETE /me/push-token`.
- An FCM **`UNREGISTERED`** error.

A phone change does **not** clear it. So the app registers:
- after every login,
- on every app start while logged in (this self-heals reinstalls and missed refreshes),
- on `onTokenRefresh`.

### Push message: what FCM delivers (`FcmPushAdapter.java`)

- **It is a notification + data message:** `notification { title, body }` plus `data`.
  - Android: priority `HIGH`, sound `default`.
  - APNs: sound `default`, **no badge**.
- **The backend sets no Android channel id and no icon.** The app must provide `default_notification_channel_id` and `default_notification_icon` in the manifest. Otherwise Android uses the low-importance "Miscellaneous" fallback channel and the launcher icon.
- **Who displays it:**
  - In the background or when terminated, the OS shows it.
  - In the foreground, **Android never shows it**, and iOS shows it only if the presentation options say so. The app decides (see Design decisions).
- **`data`** holds the event payload's top-level scalar fields as strings. Nested objects are dropped.
  - `eventKey` is always added.
  - `notificationId` is added **only when the push announces an inbox item**.
  - The inbox item's `data` is the same flat map, without those two keys.
- **Expiry and collapsing:**
  - Pushes with no inbox item carry `ttl = 120 s` (`transient-push-ttl-seconds`).
  - `offer.created` pushes collapse per ride request (`collapseKey = offer:<rideRequestId>`).

### Events (`eventKey`)

| `eventKey` | Recipient | Inbox? | `data` (besides `eventKey` / `notificationId`) |
|---|---|---|---|
| `ride.broadcasted` | drivers (cohort) | no | `rideRequestId`, `proposedFare`, `femaleOnly`, `serviceType`, `vehicleCategory`, `expiresAt` |
| `offer.created` | passenger | no | `offerId`, `rideRequestId`, `driverId`, `fare`, `direction`, `round`, `expiresAt` |
| `offer.accepted` | driver | no | `offerId`, `rideRequestId`, `rideId`, `driverId`, `fare` |
| `offer.rejected` | driver | no | `offerId`, `rideRequestId`, `reason` |
| `offer.expired` | driver | no | `offerId`, `rideRequestId` |
| `ride.accepted`, `ride.arrived` | passenger | no | `rideId`, `state`, `occurredAt` |
| `ride.started` | both | no | `rideId`, `state`, `occurredAt` |
| `ride.broadcast_cancelled` | drivers | no | `rideRequestId`, `reason` |
| `ride.request_cancelled` | passenger | no | `rideRequestId`, `reason` |
| `ride.completed` | both, each in their own role | **yes** | `rideId`, `state`, `occurredAt` |
| `ride.cancelled` (post-accept) | the party who did not cancel | **yes** | `rideId`, `actorType`, `reason`, `occurredAt` |
| `wallet.topup_approved` | driver | **yes** (DRIVER) | `topUpId`, `creditedAmountDzd`, `balanceDzd` |
| `wallet.topup_rejected` | driver | **yes** (DRIVER) | `topUpId`, `reason` |
| `wallet.penalty_charged` | driver | **yes** (DRIVER) | `rideId`, `amountDzd`, `balanceDzd` |
| `wallet.balance_low` | driver | **yes** (DRIVER) | `balanceDzd`, `thresholdDzd` |
| `wallet.balance_adjusted` | driver | **yes** (DRIVER) | `direction`, `amountDzd`, `newBalanceDzd` |
| `kyc.approved`, `kyc.rejected` | driver applicant | **yes** (DRIVER) | `driverId`, `userId`, `screen` (+ `vehicleCategory` / `submissionId`, `adminNote`) |
| `driver.revoked`, `driver.reinstated` | driver | **yes** (DRIVER) | `driverId`, `userId`, `screen` (+ `reason`, `requireRekyc`) |
| `user.blocked`, `user.suspended`, `user.reactivated` | user | **yes** (ACCOUNT, both roles) | `userId`, `screen` (+ `days`, `reason`) |

`wallet.commission_charged` has no push and no inbox item, so this feature never sees it.

### Error codes

| Code | HTTP | Client behaviour |
|---|---|---|
| `VALIDATION_ERROR` | 400 | `POST /push-token` with a blank token or an unknown platform. This is a client bug: log it in debug and don't surface it. |
| `UNAUTHORIZED` | 401 | The normal `DioClient` refresh-and-retry path. |
| `FORBIDDEN` | 403 | The token's `activeRole` is neither PASSENGER nor DRIVER. It shouldn't happen in the app. |
| `NOTIFICATION_NOT_FOUND` | 404 | Only on `…/{id}/read`: the item is gone or isn't the user's. Refetch the count and the list, and don't toast. |

---

## Design decisions

1. **Packages.**
   - `firebase_messaging: ^16.6.0` pairs with the resolved `firebase_core` 4.15.0.
   - `flutter_local_notifications: ^22.3.0` needs Flutter ≥ 3.38.1; 3.38.9 is installed. **Its API takes named params:** `initialize(settings: …)`, `show(id: …)`, `cancel(id: …)`.
2. **No WebSocket.** Nothing subscribes to `notification.created`. A foreground FCM message (`onMessage`) that carries a `notificationId` is the live "inbox changed" signal.
3. **Foreground display policy.**
   - A push **with** a `notificationId` (an inbox item) shows a local heads-up notification and signals "inbox changed", which refreshes the badge.
   - A push **without** one (trip progress, offers, broadcasts) is **not shown** in the foreground, because the ride screens the user is on already show those events.
   - On iOS, call `setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false)` so iOS doesn't auto-present every push. The local notification presents the inbox ones.
4. **Background and terminated.** The OS shows the FCM notification, so there is no `onBackgroundMessage` handler and no background isolate.
5. **Tap handling.** A tap marks the item read (when it has a `notificationId`), then navigates per the table below, but only under these conditions:
   - The user is logged in **and** onboarding is done, meaning [`AuthSession.resolveInitialRoute()`](lib/core/session/auth_session.dart#L144) returns a home route.
   - The destination belongs to the role the UI is in (`AuthSession.lastRole`). Never navigate into the other role's shell: its API calls would 403 with the wrong token.
   - Pushing the path that is already on top is skipped.
6. **Badge.** Reuse the existing 7 px dot on the bell, now driven by `unreadCount > 0`. There is no number bubble.
7. **Android channel.** Use `rapidoo_alerts` with importance high so notifications appear as heads-up banners. It is created at startup and set as the FCM default channel in the manifest.

### Tap routing table

One pure resolver (`resolveNotificationDestination`), unit-tested. `go` replaces the stack; `push` goes on top, so back returns.

| `eventKey` | Passenger role | Driver role |
|---|---|---|
| `ride.broadcasted` | none | `go` `RouteNames.availableRides` |
| `offer.created`, `ride.request_cancelled` | none (the existing home and waiting-offers flows reconcile) | none |
| `offer.accepted` | none | `go` `RouteNames.driverActiveRide` |
| `offer.rejected`, `offer.expired`, `ride.broadcast_cancelled` | none | none |
| `ride.accepted`, `ride.arrived` | `go` `RouteNames.passengerActiveRide` | none |
| `ride.started` | `go` `RouteNames.passengerActiveRide` | `go` `RouteNames.driverActiveRide` |
| `ride.completed`, `ride.cancelled` | `push` `RouteNames.passengerRideHistory` ¹ | `push` `RouteNames.driverRideDetail` (extra: `data['rideId']`) |
| `wallet.topup_approved`, `wallet.topup_rejected` | none (driver inbox) | `push` `RouteNames.driverTopUpHistory` |
| `wallet.penalty_charged`, `wallet.balance_low`, `wallet.balance_adjusted` | none | `push` `RouteNames.driverWallet` |
| `kyc.approved`, `kyc.rejected`, `driver.revoked`, `driver.reinstated` | `go` `RouteNames.driverStatusReview` ² | same |
| `user.*`, or any unknown key with a `notificationId` | `push` `RouteNames.passengerNotifications` | `push` `RouteNames.driverNotifications` |
| any unknown key without a `notificationId` | none | none |

¹ The passenger ride detail is keyed by `rideRequestId` and needs a `PassengerRideHistoryItem` as `extra`. Ride notifications only carry `rideId`, so ride history is the closest screen (see Notes).

² [driver_status_review_view.dart](lib/features/auth/presentation/views/driver/driver_status_review_view.dart) uses `PopScope(canPop: false)`, so it must be reached with `go`, never `push`. It loads the KYC status itself.

Both active-ride screens load `GET /rides/active` themselves and `go` home when there is no ride, so `go`-ing there is always safe. A cold start routes after the first frame. If the home view then finds an active ride, its own redirect wins, which is intended.

---

## Phase 0: Dependencies and native setup

- [x] `pubspec.yaml`: add `firebase_messaging: ^16.6.0` and `flutter_local_notifications: ^22.3.0`, then run `flutter pub get`. They resolved to **16.7.0** and **22.3.2**; `firebase_core` stays at 4.15.0.
- [x] Android. Verified by `flutter build apk --debug`: the merged manifest has the 3 FCM defaults plus `POST_NOTIFICATIONS`, and the APK contains the icon.
  - [x] [build.gradle.kts](android/app/build.gradle.kts): enable core library desugaring, which flutter_local_notifications 10+ requires. Add `isCoreLibraryDesugaringEnabled = true` inside `compileOptions`, and `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }` at the end. **Keep the uncommitted release `signingConfigs` changes.**
  - [x] [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml): add these entries inside `<application>`:

      ```xml
      <meta-data android:name="com.google.firebase.messaging.default_notification_channel_id"
                 android:value="rapidoo_alerts" />
      <meta-data android:name="com.google.firebase.messaging.default_notification_icon"
                 android:resource="@drawable/ic_stat_notification" />
      <meta-data android:name="com.google.firebase.messaging.default_notification_color"
                 android:resource="@color/notification_accent" />
      ```

      `POST_NOTIFICATIONS` already merges in from both plugins' manifests, so add nothing for it. `MainActivity` is already `singleTop`.
  - [x] [ic_stat_notification.xml](android/app/src/main/res/drawable/ic_stat_notification.xml): a white-on-transparent vector of the Material `directions_car` glyph. Without it, the status bar shows a white square.
  - [x] [colors.xml](android/app/src/main/res/values/colors.xml): `notification_accent` = `#FF00C853` (`AppColors.primary`).
  - [x] [raw/keep.xml](android/app/src/main/res/raw/keep.xml): `tools:keep="@drawable/ic_stat_notification"`. The plugin resolves the icon by name at runtime, which R8's resource shrinker can't see (README, "Release build configuration").
  - No `proguard-rules.pro`: for flutter_local_notifications ≥ 19 the Gson rules ship with Gson 2.12 (README "ProGuard rules"; the plugin's example file says it is no longer required).
- [x] iOS. Verified by `flutter build ios --no-codesign`: `pod install` pulled FirebaseMessaging 12.19.0, and AppDelegate compiles. All three plists pass `plutil -lint`.
  - [x] [Info.plist](ios/Runner/Info.plist): `UIBackgroundModes` → `remote-notification`.
  - [x] New `ios/Runner/Runner.entitlements`: `aps-environment` = `development`.
  - [x] [project.pbxproj](ios/Runner.xcodeproj/project.pbxproj): `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` on the 3 Runner build configs (Debug / Release / Profile; bundle `com.rapidoo.app`, team `8KY5PFU9D5`). Alternatively, add the Push Notifications and Background Modes ▸ Remote notifications capabilities in Xcode, which writes the same thing.
  - [x] [AppDelegate.swift](ios/Runner/AppDelegate.swift): add `import UserNotifications`, plus this line before `GeneratedPluginRegistrant.register(with: self)`:
        `UNUserNotificationCenter.current().delegate = self`
        It is a flutter_local_notifications requirement, and it is how foreground local notifications get presented. A plain `self` works, without the README's `as?` cast, because `FlutterAppDelegate` already conforms to `UNUserNotificationCenterDelegate` through `FlutterAppLifeCycleProvider`.
  - **No iOS FCM token yet, and that is expected.** There is no paid Apple Developer account yet, so there is no APNs key in Firebase, and iOS returns no FCM token. The config above stays in place, ready for when the account exists. Until then:
    - A missing iOS token is **not a bug**. The app must work normally without it (see `registerDevice()` in Phase 2).
    - A physical-iPhone build signed with a free (personal) team fails provisioning, because personal teams don't support the Push Notifications capability (`aps-environment`). If that blocks a device run, temporarily delete the three `CODE_SIGN_ENTITLEMENTS` lines. Simulator builds and `--no-codesign` builds are unaffected.

## Phase 1: Data layer

Verified: `flutter analyze` reports nothing in these files, and `flutter test` passes, including the model test pulled forward from Phase 7.

- [x] [me_api_constants.dart](lib/core/constants/me_api_constants.dart): add the `/api/me` paths:
  - [x] `pushToken` = `$_base/push-token`
  - [x] `notifications` = `$_base/notifications`
  - [x] `notificationsUnreadCount` = `$_base/notifications/unread-count`
  - [x] `notificationRead(String id)` = `$_base/notifications/$id/read`
  - [x] `notificationsReadAll` = `$_base/notifications/read-all`
- [x] [app_notification.dart](lib/features/notifications/data/models/app_notification.dart)
  - [x] `AppNotification` with `id`, `eventKey`, `title`, `body`, `data` (`Map<String, String>`), `read`, `createdAt`, `readAt?`. The dates stay ISO strings, as in the wallet models.
  - [x] `fromJson` coerces every `data` value with `toString()` and tolerates a missing or `null` `data` / `readAt`.
    - A `null` value inside `data` is dropped, not turned into the string `"null"`.
    - A row without an `id` throws, so `PageResponse` drops it.
  - [x] `copyWith(read:)` for optimistic mark-read.
- [x] [push_platform.dart](lib/features/notifications/data/models/push_platform.dart): `PushPlatform { ios, android }` with a `wireName` (`IOS` / `ANDROID`), so an unknown platform (`400 VALIDATION_ERROR`) can't be sent.
- [x] [notification_repository.dart](lib/features/notifications/data/notification_repository.dart): a `const NotificationRepository()` over `DioClient`.
  - [x] `registerPushToken({token, platform})` → `POST pushToken`
  - [x] `list({page = 0, size = 20})` → `PageResponse.fromJson(json, AppNotification.fromJson)`
  - [x] `unreadCount()` → `int`
  - [x] `markRead(id)`
  - [x] `markAllRead()` → `int` updated

> Note: the Dio idempotency interceptor attaches an `Idempotency-Key` to these POSTs, because it only skips `/api/auth/*`. That is harmless.

## Phase 2: `PushNotificationService` ([push_notification_service.dart](lib/core/push/push_notification_service.dart))

A static singleton (`final class`, private constructor, static members), the same style as [dio_client.dart](lib/core/network/dio_client.dart).

Verified: `flutter analyze` reports nothing in these files, and `flutter test` passes. The service doesn't run yet, because nothing calls it until Phase 6.

Also added in this phase:
- [string_map.dart](lib/core/utils/string_map.dart): `asStringMap()`, moved out of `AppNotification`. The model, FCM's `RemoteMessage.data` and the local-notification payload now share one coercion rule.
- [notification_navigator.dart](lib/core/push/notification_navigator.dart): a placeholder `NotificationNavigator.openFromPush` that only logs, so that Phase 2 compiles before Phase 3 exists.
- `init()`, `handleLaunchTap()`, `registerDevice()` and `clearDisplayed()` never throw. `init()` runs before `runApp`, so a push failure must not block startup.

- [x] **`init()`**, awaited in `main()` before `runApp`:
  - [x] Initialise `FlutterLocalNotificationsPlugin` with `AndroidInitializationSettings('@drawable/ic_stat_notification')` and `DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false)`. Those default to `true` and would prompt on the phone-entry screen.
  - [x] Create the Android channel `AndroidNotificationChannel('rapidoo_alerts', …, importance: Importance.high)`. Its user-visible name is "Alerts".
  - [x] Call `FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false)`. The plugin makes this a no-op on Android.
  - [x] **`onMessage`**, the foreground policy:
    - [x] If `data['notificationId']` is present, emit on `inboxChanges`. If the message also has a `notification` block, `show()` a local notification (title and body from it, payload `jsonEncode(data)`).
    - [x] Otherwise, ignore the message.
  - [x] **`onMessageOpenedApp`**: background → foreground via a tap → `NotificationNavigator.openFromPush(data)`.
  - [x] **Local notification tap** (`onDidReceiveNotificationResponse`): decode the payload → `openFromPush`.
  - [x] **`onTokenRefresh`**: cache the new token; if `AuthSession.isLoggedIn`, re-register it.
- [x] **`handleLaunchTap()`**, called after `runApp`:
  - [x] Cold start from an FCM tap: `getInitialMessage()`.
  - [x] Cold start from a local-notification tap: `getNotificationAppLaunchDetails()`, only when `didNotificationLaunchApp` is true.
  - [x] Route after `await WidgetsBinding.instance.endOfFrame`, so the router is mounted.
    - It is not a bare `addPostFrameCallback`. The platform calls can finish after the first frame, and a post-frame callback doesn't schedule a frame of its own, so it could wait indefinitely.
    - `endOfFrame` schedules a frame when none is pending.
- [x] **`registerDevice()`**: best-effort, de-duplicated while in flight, and it **never throws**.
  - [x] Call `requestPermission()`. This is also the Android 13+ `POST_NOTIFICATIONS` prompt, and it prompts only once.
  - [x] Register even if permission is denied: it is harmless, and pushes start working if the user enables them later in OS settings.
  - [x] On iOS, wait briefly for `getAPNSToken()` before `getToken()` (up to 5 tries, 1 s apart); otherwise it fails with `apns-token-not-set`.
  - [x] **No token is a normal outcome.** If the APNs token is still `null` after the wait, or `getToken()` throws or returns `null`:
    - skip registration quietly: one `debugPrint` in debug builds, no toast, no error state, no retry loop;
    - leave `_token` `null`, so `logout` sends `{}`.

    This is the current state on iOS until the Apple Developer account exists (see Phase 0 ▸ iOS).
  - [x] Call `getToken()` → `registerPushToken(token: token, platform: Platform.isIOS ? PushPlatform.ios : PushPlatform.android)` → cache `_token`.
  - [x] `debugPrint` the token in debug builds, for Firebase console test messages.
- [x] **`currentToken()`**: returns the cached `_token`, otherwise `getToken()` with a 3 s timeout; `null` on failure.
- [x] **`inboxChanges`**: a broadcast `Stream<void>`, the socket-free stand-in for `notification.created`. **`notifyInboxChanged()`** emits on it.
- [x] **`clearDisplayed()`**: `cancelAll()`, used on logout.
- [x] Local notification id = `notificationId.hashCode & 0x7fffffff`, so a re-push of the same item replaces it instead of stacking.

## Phase 3: Tap routing (`lib/core/push/notification_destination.dart`)

`NotificationNavigator` lives in [notification_navigator.dart](lib/core/push/notification_navigator.dart). Phase 2 created it as a placeholder, and this phase fills it in. [notification_destination.dart](lib/core/push/notification_destination.dart) holds only the pure resolver, so its unit test doesn't import the router.

Verified: `flutter analyze` reports nothing in these files, and `flutter test` passes, including the resolver test pulled forward from Phase 7. Real taps wait for Phase 5 (the inbox routes) and Phase 6 (`init()`).

- [x] A pure `resolveNotificationDestination({eventKey, data, ActiveRole role})` returning `({String path, Object? extra, bool replace})?`, typedef'd as `NotificationDestination`.
  - [x] It implements the tap routing table exactly. `ActiveRole` comes from [token_payload.dart](lib/core/models/token_payload.dart).
  - [x] It returns `null` for cross-role targets and for "none" rows. A cross-role inbox item stays `null` too, even with a `notificationId`: for example `wallet.*` in the passenger role, whose item lives in the driver inbox.
  - [x] Beyond the table:
    - `ActiveRole.unknown` returns `null`.
    - A driver `ride.completed` or `ride.cancelled` with no `rideId` pushes `driverRideHistory` instead of a detail screen with no id to load.
- [x] `NotificationNavigator.open(eventKey, data)`:
  - [x] Guards: logged in, onboarding done (`resolveInitialRoute()` ∈ {`passengerHome`, `driverHome`}), and the role taken from `AuthSession.lastRole`.
    - One `switch` on `resolveInitialRoute()` does all three, because that method picks `driverHome` exactly when `lastRole` is `DRIVER`.
  - [x] Applies the destination with `AppRouter.router.go(...)` or `.push(...)`. This is the same static use as [dio_client.dart:33](lib/core/network/dio_client.dart#L33).
  - [x] Skips a `push` when the current location already equals the target path. The check is `AppRouter.router.state.matchedLocation`, the top route, pushed ones included (go_router 14.8.1).
- [x] `NotificationNavigator.openFromPush(data)`: if there is a `notificationId`, fire-and-forget `markRead`, then `PushNotificationService.notifyInboxChanged()`. After that, `open(data['eventKey'], data)`.
  - `notifyInboxChanged()` fires once `markRead` finishes, whether it succeeded or failed. The refetched count then already excludes the item, instead of racing the read.
  - A `404` is only logged; the refresh realigns the view.

## Phase 4: State (`NotificationsCubit`)

Under `lib/features/notifications/presentation/cubit/notifications_cubit/`: [notifications_cubit.dart](lib/features/notifications/presentation/cubit/notifications_cubit/notifications_cubit.dart) and [notifications_state.dart](lib/features/notifications/presentation/cubit/notifications_cubit/notifications_state.dart).

Verified: `flutter analyze` reports nothing in these files, and `flutter test` passes, including the new cubit test.

- **Mutation check:** with the race guards removed, both race tests fail. They pass with the guards back.
- **No on-device check yet:** the provider is lazy, and nothing reads it until Phase 5 wires the bell.

Design notes:
- **`isClosed` guards:**
  - Every emit after an `await` checks `isClosed` first.
  - In bloc 8.1.4, `emit` after `close` throws. Refreshes run in the background, and a role switch or logout can dispose the shell while one is in flight.
- **Count beside the list:**
  - `load` fetches the count *alongside* the list, through the best-effort `refreshUnreadCount()`.
  - It doesn't combine them with a record `.wait`. A failure there becomes a `ParallelWaitError` whose `toString()` prefixes the message ("ParallelWaitError: …"), and a count failure would blank the list.
- **Stale results:**
  - A load generation counter drops an older `load` that lands after a newer one.
  - `loadMore` drops its page when a reload restarted the list meanwhile (`currentPage` moved), and it skips ids already on screen.
- **A non-silent `load` resets the list:** items, `currentPage` and `totalPages` all start over, the same as ride history's `loadHistory`.
- **The repository is a plain `class`:** `NotificationRepository` is now a plain `class`, not `final`, so the test can extend it. It is the same as `RoutingRepository`.

- [x] `NotificationsState` (Equatable):
  - [x] Fields: `status` (`initial`, `loading`, `loaded`, `loadingMore`, `failure`), `items`, `currentPage`, `totalPages`, `unreadCount`, `errorMessage`.
  - [x] Getters: `isLoading`, `isLoadingMore`, `hasReachedMax`, the same as [passenger_ride_history_state.dart](lib/features/ride/passenger/presentation/cubit/passenger_ride_history_cubit/passenger_ride_history_state.dart), plus `hasUnread`.
- [x] `NotificationsCubit(NotificationRepository)`:
  - [x] `refreshUnreadCount()`: best-effort; keeps the old count on error.
  - [x] `load({bool silent = false})`: page 0 plus the count. `silent` keeps the current list on screen (no full-screen spinner). It is also the pull-to-refresh action.
    - A silent failure keeps the status and items and sets only `errorMessage`.
  - [x] `loadMore()`: appends the next page; on error it keeps the items and sets `errorMessage` for a toast.
  - [x] `markRead(id)`: optimistic. It flips the item to `read`, decrements `unreadCount` (not below 0), then calls the API. On `404` it reloads silently.
    - Any failure reloads silently, not only a `404`, so the view realigns with the server.
    - With no network, that reload surfaces the connection error.
    - An item that is already read, or not loaded, makes no call.
  - [x] `markAllRead()`: optimistic. All items become read and the count becomes 0, then the API is called; on failure it reloads.
  - [x] Subscribes to `PushNotificationService.inboxChanges` and creates an `AppLifecycleListener(onResume: …)`. Both call `refreshUnreadCount()`, plus `load(silent: true)` if the list was already loaded.
    - A loaded list gets `load(silent: true)` alone, because that load already includes the count.
    - Any other status gets only `refreshUnreadCount()`, which also avoids reloading under an in-flight `loadMore`.
  - [x] `close()` cancels the subscription and disposes the listener, the same way [wallet_cubit.dart](lib/features/wallet/driver/presentation/cubit/wallet_cubit/wallet_cubit.dart) disposes its subscriptions.
- [x] Provided at **both** `ShellRoute`s in [app_router.dart](lib/core/router/app_router.dart), created with `..refreshUnreadCount()`. Role switch and logout dispose the shell, so it resets with no extra code. The provider is lazy, like the others; Phase 5's bell is the first reader.
  - [x] Passenger shell ([app_router.dart:138](lib/core/router/app_router.dart#L138)): turn the single `BlocProvider` into a `MultiBlocProvider`.
  - [x] Driver shell ([app_router.dart:319](lib/core/router/app_router.dart#L319)): add it to the existing `providers`.

## Phase 5: UI

- [x] [route_names.dart](lib/core/router/route_names.dart): add `passengerNotifications = '/passenger-notifications'` and `driverNotifications = '/driver-notifications'`. Added in Phase 3, because the resolver needs them.
- [ ] [app_router.dart](lib/core/router/app_router.dart): add one `GoRoute` per shell, both building `const NotificationsView()`. The cubit comes from the shell.
- [ ] `lib/features/notifications/presentation/views/notifications_view.dart`
  - [ ] `initState` calls `context.read<NotificationsCubit>().load()`.
  - [ ] Header: `AppTopBar(title: 'Notifications', leadingIcon: back, onLeadingTap: context.pop)`. The trailing `Icons.done_all_rounded` (mark all read) appears only when `hasUnread`, with no badge.
  - [ ] The list follows [passenger_ride_history_view.dart](lib/features/ride/passenger/presentation/views/passenger_ride_history_view.dart):
    - `RefreshIndicator` and `ListView.builder` with a paging footer.
    - Scroll-near-end calls `loadMore()`.
    - A `BlocConsumer` toasts transient errors when items exist.
  - [ ] States: loading spinner, failure with message, and an empty state ("No notifications yet").
  - [ ] A tile tap calls `markRead(item.id)` (if unread), then `NotificationNavigator.open(item.eventKey, item.data)`.
- [ ] `lib/features/notifications/presentation/views/widgets/notification_tile.dart`
  - [ ] The icon comes from the `eventKey` prefix: `ride.` → car, `wallet.` → wallet, `kyc.` / `driver.` → verified badge, `user.` → shield, anything else → bell.
  - [ ] Shows the title, a 2–3 line body, and a relative time. Unread tiles get bold text, a primary dot and a light tint.
- [ ] `lib/features/notifications/utils/notification_time_formatter.dart`: returns "Just now", "N min ago", "N h ago" or "Yesterday", otherwise `formatRideDate` from [date_formatter.dart](lib/features/ride/shared/utils/date_formatter.dart). The project has no `intl`.
- [ ] Bell wiring
  - [ ] [app_top_bar.dart](lib/shared/widgets/app_top_bar.dart): add `showTrailingBadge` (default `true`, so every other trailing button keeps today's dot) and use it instead of the hard-coded `showBadge: true`.
  - [ ] [shared/widgets/top_bar.dart](lib/shared/widgets/top_bar.dart): add `showTrailingBadge` (default `false`) and pass it through. Only the three bell screens use this widget. The other screens import the duplicate in `features/home/passenger/.../top_bar.dart`, which stays untouched.
  - [ ] [passenger_home_view.dart:95](lib/features/home/passenger/presentation/views/passenger_home_view.dart#L95), [driver_home_view.dart:40](lib/features/home/driver/presentation/views/driver_home_view.dart#L40) and [available_rides_view.dart:34](lib/features/ride/driver/presentation/views/available_rides_view.dart#L34): wrap `TopBar` in `BlocSelector<NotificationsCubit, NotificationsState, bool>` (`hasUnread`), with `onTrailingTap: () => context.push(RouteNames.passengerNotifications / driverNotifications)`.

## Phase 6: Auth hooks and app start

- [ ] [auth_repository.dart](lib/features/auth/data/repo/auth_repository.dart)
  - [ ] `verifyOtp`: after `AuthSession.setTokens(...)`, call `unawaited(PushNotificationService.registerDevice())`. The server cleared the token during this login, so registering now is the right order.
  - [ ] `logout`: body `{'pushToken': token}` when `currentToken()` returns one, otherwise `{}` as today. After `AuthSession.clearSession()`, call `PushNotificationService.clearDisplayed()`.
- [ ] [main.dart](lib/main.dart)
  - [ ] After `DioClient.init()`: `await PushNotificationService.init()`.
  - [ ] After `runApp(...)`: `PushNotificationService.handleLaunchTap()`, and `unawaited(PushNotificationService.registerDevice())` when `AuthSession.isLoggedIn`.

## Phase 7: Tests and docs

Use the flat `test/` layout of the existing tests (e.g. [date_formatter_test.dart](test/date_formatter_test.dart)).

- [x] [notification_destination_test.dart](test/notification_destination_test.dart): every table row for both roles, cross-role targets → `null`, and unknown keys with and without a `notificationId`. Written in Phase 3; it also covers the `rideId` fallback and the `unknown` role.
- [x] [app_notification_test.dart](test/app_notification_test.dart): full parse, non-string `data` values, a missing `data`, and a `null` `readAt`. Written in Phase 1; it also covers `copyWith` and a `PageResponse` row without an `id`.
- [x] [notifications_cubit_test.dart](test/notifications_cubit_test.dart): load, optimistic `markRead` / `markAllRead` and their reloads on failure, `loadMore` dedupe and dropping stale pages, silent vs non-silent failures, `inboxChanges` refreshes, and no emit after `close`. Added in Phase 4; it wasn't in the original list.
- [ ] `test/notification_time_formatter_test.dart`: each bucket, plus the fallback date.
- [ ] [CLAUDE.md](CLAUDE.md): add a short "Push notifications" subsection covering the `PushNotificationService` singleton, the no-WS rule and the token lifecycle. Also fix the stale "test/ is currently empty" note.

## Phase 8: Manual prerequisites (outside the code)

- [ ] **Firebase console → Project settings → Cloud Messaging → Apple app:** upload an APNs auth key (`.p8`) for `com.rapidoo.app`. Without it, iOS receives nothing. **Blocked:** it needs a paid Apple Developer Program account, which doesn't exist yet.
- [ ] **Xcode:** open the project once and confirm that Signing & Capabilities shows Push Notifications and Background Modes ▸ Remote notifications. Automatic signing then enables push on the App ID. **Blocked** on the same account: free personal teams can't enable Push Notifications.
- [ ] **Backend dev server** (`vtc-api-dev.duckdns.org`): must run with `PUSH_PROVIDER=fcm` and `FIREBASE_CREDENTIALS_JSON` taken from a service account of the **same** Firebase project, `rapido-1956d`. The default is `mock`, which only logs.

## Phase 9: Verification

- [ ] `flutter analyze` is clean.
- [ ] `flutter test` passes, new and existing tests.
- [ ] No socket in notification code: `grep -rnE "notification\.created|RideSocketService|frameStream|statusStream" lib/core/push lib/features/notifications` finds nothing.
- [ ] **Android emulator** (Google Play image)
  - [ ] Log in: the permission prompt appears, and the debug log shows `POST /api/me/push-token` → `200` and the FCM token.
  - [ ] Send a test message from the Firebase console to that token with data `{eventKey: wallet.topup_approved, notificationId: <id>}`.
    - [ ] Background: a heads-up appears with the custom icon and color, and a tap opens top-up history.
    - [ ] Terminated: a tap cold-starts the app straight into top-up history.
    - [ ] Foreground: a local banner shows, and the bell dot appears.
  - [ ] A transient key (no `notificationId`) sent while in the foreground: nothing is shown.
- [ ] **Real events**
  - [ ] Complete a ride: both roles get a push, and the badge and inbox update. The driver's tap opens the ride detail and the passenger's opens ride history.
  - [ ] Approve a top-up from the admin dashboard: the push arrives, and the item appears in the driver inbox.
  - [ ] Inbox: pagination, pull-to-refresh, tap → marked read and the dot clears, mark-all-read → count 0.
  - [ ] Switch role: the other role's unread count loads.
  - [ ] Logout: the request body contains `pushToken`, and no further pushes arrive.
- [ ] **iOS physical device:** repeat the background, terminated and foreground cases. **Deferred** until the Apple Developer account and APNs key exist. Until then, only check that the iOS app runs normally with no FCM token: no crash, no error toast, and the inbox still works over REST.
- [ ] **Release build:** `flutter build apk --release`, then repeat one foreground banner to confirm R8 resource shrinking keeps the notification icon (`raw/keep.xml`).

---

## Notes / open questions

- **Passenger ride deep link.** `ride.completed` and `ride.cancelled` carry only `rideId`, while `GET /api/passenger/rides/{rideRequestId}` needs a `rideRequestId`, so passenger taps open ride history. Ask the backend to add `rideRequestId` to those payloads to deep-link to the detail. Also, `docs/api/passenger.md` documents that endpoint as `GET /rides/{rideId}`, but the controller maps `/{rideRequestId}`. Worth flagging.
- **KYC, wallet and driver items live in the DRIVER inbox only.** A not-yet-approved applicant in passenger mode still gets the `kyc.approved` push, and its tap still routes to `driverStatusReview`, but the item isn't in the passenger inbox.
- **No app-icon badge.** The APNs config sends no `badge`, and the in-app dot is the only unread indicator.
- **Push opt-out** (`DELETE /me/push-token`) needs a settings screen, and the drawer "Settings" item is still a placeholder.
- **Out of scope:**
  - Any WebSocket handling for notifications (`notification.created` on `/ws/passenger` and `/ws/driver`), by decision
  - Admin notifications (`/api/admin/notifications`, `/ws/admin`)
  - Refreshing wallet or ride state from push payloads
  - Per-type notification preferences (still an open question on the backend too)
