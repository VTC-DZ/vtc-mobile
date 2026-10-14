# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`rapidoo` — an inDrive-style ride-hailing app for Algeria (whole-DZD fares, phone-OTP auth, passenger-vs-driver fare negotiation, driver KYC, a driver commission wallet, push notifications). Flutter app, Dart SDK `^3.6.0`, **Android and iOS only** (`firebase_options.dart` throws on web/desktop). Built against a Spring backend — REST + raw-WebSocket "VTC" API — plus Firebase Cloud Messaging.

## Common commands

```bash
flutter pub get                                   # install/refresh dependencies
flutter run                                       # run on the selected device (use -d <deviceId>)
flutter analyze                                   # static analysis (flutter_lints) — run before considering work done
flutter test                                      # all tests
flutter test test/features/auth                   # one folder: a feature, core/ or shared/
flutter test test/core/utils/map_geo_test.dart    # one file
flutter test --plain-name "passenger role"        # tests whose group/test name contains the string
flutter build apk                                 # or: flutter build ios
```

`flutter analyze` is not at zero: a few pre-existing `info` lints (`avoid_print` in the Bloc observer, `use_build_context_synchronously` in the home drawers) are the baseline — don't add new issues.

Backend target is `ApiConstants.baseUrl` in [api_constants.dart](lib/core/constants/api_constants.dart) — currently the hosted dev API `https://vtc-api-dev.duckdns.org` (Swagger UI at `/swagger-ui.html`). For a backend on your own machine use `http://localhost:8080`, or `http://10.0.2.2:8080` from the **Android emulator**. The WS base URL is derived from this REST base automatically ([ws_url.dart](lib/core/network/ws_url.dart)) — do not introduce a separate `wsBaseUrl` constant.

## Architecture

### Feature-sliced layout (`lib/`)

- **`core/`** — cross-cutting infrastructure: `network/` (DioClient, RideSocketService, DriverLocationStreamer), `push/` (PushNotificationService + notification tap routing), `session/` (AuthSession, SessionTeardown), `router/` (go_router config, RouteNames, the start-route resolver), `presentation/` (WebSocketConnectionCubit), `storage/` (SecureStorageHelper), `constants/` (per-surface API path + error-code constants, app strings, validation patterns), `errors/` (ApiException), `models/` (TokenPayload/ActiveRole, AuthTokensModel, Gender), `theme/`, `utils/` (map geometry/markers, validators, phone/plate/date/countdown formatting, jwt_decoder, uuid), `widgets/` (AppToast, dialogs).
- **`features/`** — vertical slices mirroring the passenger/driver split: `auth`, `home/{passenger,driver}`, `ride/{passenger,driver,shared}`, `profile/{passenger,driver,shared}`, `wallet/driver`, `notifications`, `saved_places`. Inside a slice: `data/` (repositories, data-layer services such as pickers, and `models/`) and `presentation/` (`cubit/` + `views/` + `views/widgets/`). `profile/shared/data/` owns the `/api/me` account data (`ProfileRepository`, `PassengerProfileModel`, `DriverProfileModel`, `KycStatus`) that auth, home and profile all read.
- **`shared/widgets/`** — cross-feature reusable widgets (app bars, bottom sheets, buttons, text fields; `form/` for profile form fields, `otp/` for the OTP banners and resend row). `shared/` and `core/` never import a feature.

Driver onboarding/KYC runs on `DriverRegistrationCubit` (`features/auth/.../driver_registration_cubit`, screen `DriverRegistrationView`). The unrelated `DriverProfileCubit` in `features/profile/driver/` edits an existing driver profile.

### Infrastructure is static singletons (no DI container)

`DioClient`, `RideSocketService`, `DriverLocationStreamer`, `PushNotificationService`, and `AuthSession` are `final class` with a private constructor and `static` members. `AppRouter.router` is a static `GoRouter`, which is how infrastructure navigates outside the widget tree (forced logout, notification taps). Repositories are `const`-constructible classes (e.g. `const PassengerRideRepository()`) that call these singletons statically; they are passed into the Cubit in the route's `BlocProvider` (see [app_router.dart](lib/core/router/app_router.dart)) — not registered anywhere.

### State & navigation

- **State:** `flutter_bloc` Cubits + `equatable` immutable states. `MyBlocObserver` ([observer.dart](lib/core/helper/observer.dart)) logs every create/change/error/close — intentionally verbose; expect noisy debug output.
- **Navigation:** `go_router`. Paths are constants in [route_names.dart](lib/core/router/route_names.dart) — always `RouteNames.*`, never raw strings. Screen arguments travel in `state.extra` (an `*Args` object, a model, or an id string), not path/query params.
- **Shells:** the passenger and driver home areas are `ShellRoute`s whose builders provide Cubits that must survive navigation between sibling screens; a role switch or logout leaves the shell and disposes them.
  - passenger: `PassengerHomeCubit`, `NotificationsCubit` (plus a nested shell providing `SavedPlacesCubit`)
  - driver: `DriverHomeCubit`, `DriverAvailabilityCubit`, `WebSocketConnectionCubit`, `AvailableRidesCubit` (keeps collecting `ride.broadcast` while online), `WalletCubit` (balance gate), `NotificationsCubit`
- **Startup route:** `initialRouteForSession()` → the pure, unit-tested `resolveInitialRoute(...)` ([initial_route.dart](lib/core/router/initial_route.dart)) — no token → phone entry; new user who hasn't applied as a driver → mode selection; otherwise driver or passenger home by the persisted `lastRole`.
- **Responsive sizing:** `flutter_screenutil` (design size in `AppConstants.designWidth/Height`). Use `.h/.w/.sp`. Fonts come from `google_fonts` (Plus Jakarta Sans + Inter) — no TTF assets.
- **User feedback:** `AppToast.success/warning/error` ([app_toast.dart](lib/core/widgets/app_toast.dart)).

### Networking — `DioClient` ([dio_client.dart](lib/core/network/dio_client.dart))

All backend HTTP goes through `DioClient.get/post/put/delete/patch/postMultipart`. Interceptors, in order:
1. **Auth:** attaches `Authorization: Bearer <accessToken>` from `AuthSession`, unless the request set its own `Authorization` header (the refresh call sends `null` to strip it).
2. **Idempotency:** adds a fresh `Idempotency-Key` (`uuidV4()`) to every POST/PUT/DELETE **except** `/api/auth/*`. This makes retries safe — do not strip it.
3. **401 refresh:** concurrent 401s all join one in-flight `DioClient.refreshAccessToken()`, then the original request is retried. The backend **rotates refresh tokens on use**, so anything needing a refresh (including `RideSocketService`) must go through `refreshAccessToken()` — never call `/api/auth/refresh` directly. Only a refresh the server rejects with a 401 (`session_invalid`) — or any other 401 from `/api/auth/*` — forces logout, through `SessionTeardown.run()` ([session_teardown.dart](lib/core/session/session_teardown.dart)): stop location streaming, disconnect the socket, clear the session, `go(RouteNames.phone)`. Logout and the socket's forced re-login use the same teardown — never write the sequence out again. A refresh that times out, finds no network or gets a 5xx passes the original error on and keeps the session; the next request tries again. A 401/403 that persists after a good refresh is an ordinary error and keeps the session too.
4. **Logging** (debug only): full request/response bodies.

**Errors:** every helper throws [`ApiException`](lib/core/errors/api_exception.dart) — `message` (already localised by the backend; show as-is), `code` (from the `{error:{code,message,details}}` envelope), `statusCode`, `retryAfter`. `toString()` returns the message, so `catch (e)` → `e.toString()` renders text. To branch, use `e is ApiException && e.isConflict` or `e.hasCode(RideErrorCodes.x)` — never match message text. Error-code constants sit beside the path constants (`AuthErrorCodes`, `KycErrorCodes`, `RideErrorCodes`, `PassengerRideErrorCodes`, `WalletErrorCodes` in `core/constants/*_api_constants.dart`). The server sends most codes in lower case, whatever its docs say.

**Third-party hosts never go through `DioClient`** (it would send them the JWT). `RoutingRepository` keeps its own bare `Dio` for road routes from the public OSRM demo server (`RoutingApiConstants`) — no SLA, to be replaced by a backend endpoint before release.

### Realtime — raw WebSocket, NOT STOMP ([ride_socket_service.dart](lib/core/network/ride_socket_service.dart))

> ⚠️ The transport is a **plain WebSocket** (`IOWebSocketChannel`). There is no STOMP, no SockJS, no topic subscriptions. Do **not** add a STOMP client library. One socket per role (`/ws/passenger`, `/ws/driver`); the JWT goes in the `Authorization` header of the upgrade request, and `/ws/driver` additionally requires `activeRole == DRIVER`.

`RideSocketService` owns the connection lifecycle only:
- `connect(ActiveRole)`, `disconnect()`, `send(envelope)`, and auto-reconnect with exponential backoff (`1→2→4→8→16s` ±20 % jitter, `WebSocketConstants.backoffSteps`), exactly one reconnect per failure. The status turns `connected` only once the server has accepted the handshake (10 s timeout); until then `send` writes nothing. Connecting for the other role tears down the current socket first. `connect()` completes when the attempt settles, so callers that don't need the socket yet wrap it in `unawaited(...)`. `disconnect()` is synchronous and never waits for the close handshake.
- Every attempt carries a generation number that `connect()`/`disconnect()` bump, so an overtaken attempt's callbacks are ignored. The decisions — backoff, handshake 401, token freshness, close codes `1000`/`4001`/`4002`/`4003`/`4004` — are pure functions in [ride_socket_policy.dart](lib/core/network/ride_socket_policy.dart). Tests swap the channel and the refresh through the `@visibleForTesting` `channelFactory` and `refreshAccessToken`.
- **Token refresh:** the server checks the token only at the handshake and answers an expired one with HTTP 401; it never sends `system.token_expiring`, `4001` or `4003` today. So before every (re)connect the service refreshes a token that expires within 60 s, and a handshake 401 (or a close `4001`) gets one refresh and an immediate retry; a second refusal in a row emits `failed` until the next explicit `connect()`. A `system.token_expiring` frame still refreshes in place and sends `system.auth_refresh`. Every refresh goes through `DioClient.refreshAccessToken()`. A close `4003` ends the session via `SessionTeardown.run()`. A refresh the server rejects has already ended it in `DioClient`; any other refresh failure keeps it and retries on the backoff.
- **Keep-alive:** the server never pings, and Tomcat closes a socket after 60 s without an inbound frame, so the client's 10 s ping (`WebSocketConstants.pingInterval`) is what keeps it open. It also notices a dead link in about 20 s.

Who opens it: the **driver** socket by `DriverAvailabilityCubit` on go-online (with `DriverLocationStreamer.start()`), closed on go-offline; the **passenger** socket by `RideRequestCubit`, `WaitingOffersCubit` and `PassengerActiveRideCubit`. Logout runs `SessionTeardown.run()`; `AuthRepository.switchRole(ActiveRole.passenger)` calls `DriverLocationStreamer.stopAndDisconnect()` before storing the passenger token.

It exposes two streams:
- `statusStream` → `RideSocketStatus {disconnected, connecting, connected, reconnecting, failed}`, mirrored to UI by `WebSocketConnectionCubit`.
- `frameStream` → raw envelope JSON strings (unparsed by design). Cubits subscribe, decode with `RideSocketEvent.tryParse`, and switch on the sealed event type. The single parser lives in [ride_socket_event.dart](lib/features/ride/driver/data/models/ride_socket_event.dart) despite the `driver/` path — it covers passenger, driver, `wallet.*` and `system.*` events. Subscribers: `AvailableRidesCubit`, `DriverActiveRideCubit`, `WaitingOffersCubit`, `PassengerActiveRideCubit`, `WalletCubit`.

`DriverLocationStreamer` ([driver_location_streamer.dart](lib/core/network/driver_location_streamer.dart)) sends the driver's GPS every 15s while armed: as a `driver.location` WS envelope when the driver socket is up, otherwise via REST `POST /api/driver/location`, plus an immediate send on reconnect.

### Auth & session — `AuthSession` ([auth_session.dart](lib/core/session/auth_session.dart))

Static singleton holding access/refresh tokens plus flags (`isNewUser`, `waitingKycStatus`, `hasDriverProfile`, `lastRole`), persisted to `flutter_secure_storage`. Its setters (`setTokens`, `setAccessToken`, …) update memory and storage together — use them rather than `SecureStorageHelper` directly. Repositories own these writes (e.g. `verifyOtp`, `saveProfile`, `submitKyc`, `getKycStatus`); views and cubits only read the flags, so cubits stay unit-testable. JWT claims (`activeRole`, `kycVerified`, `hasDriverProfile`, …) are decoded by `JwtDecoder` + `TokenPayload` ([token_payload.dart](lib/core/models/token_payload.dart)), which also defines `ActiveRole` (with its `wireValue`; `AuthSession.lastRole` is an `ActiveRole` stored as `'DRIVER'`/`'PASSENGER'`). `AuthRepository.switchRole(ActiveRole)`, called from the home drawers, swaps in an access token for the other `activeRole`.

### Push notifications — FCM + REST inbox, never the socket

> ⚠️ Notifications use **FCM push** and the **REST inbox** (`/api/me/notifications`) only. Do not handle the `notification.created` WS frame (the backend handoff [Untitled.md](Untitled.md) still lists it), do not add a notification type to `RideSocketEventType`, and do not import `RideSocketService` from notification code.

- [`PushNotificationService`](lib/core/push/push_notification_service.dart) owns FCM + `flutter_local_notifications`: `init()` before `runApp`, `handleLaunchTap()` after it, `registerDevice()` on every logged-in app start and after every login (the server clears the stored token on login and logout). None of them throw — push must never block startup. In the foreground only pushes carrying a `notificationId` (inbox items) are shown and emit `inboxChanges`; trip-progress and offer pushes are skipped because the ride screens already show them.
- **Tap routing:** [`resolveNotificationDestination`](lib/core/push/notification_destination.dart) is a pure, unit-tested function mapping `eventKey` + `data` + role to a route and `go`-vs-`push`; `NotificationNavigator` applies it via `AppRouter.router` and ignores targets in the other role's shell. It implements the tap routing table in [NOTIFICATION_PROGRESS.md](NOTIFICATION_PROGRESS.md) — change both together.
- `NotificationsCubit` is shell-scoped in both shells (the bell's badge and the inbox share one unread count) and refetches on `inboxChanges` and app resume.
- The Android channel id `rapidoo_alerts` must match `default_notification_channel_id` in [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml).
- **iOS has no FCM token until a paid Apple Developer account exists.** That is expected — `registerDevice()` skips with a debug log. Keep the iOS push config; don't try to fix it.
- Firebase config (`lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`) is FlutterFire-generated for project `rapido-1956d`.

### Driver wallet (`features/wallet/driver`)

The driver's prepaid platform commission — not fare payment (rides are paid in cash). Amounts are whole-DZD ints, and a negative balance is valid (driver debt). `WalletCubit` lives in the driver shell and applies `wallet.*` events from the driver socket. Below the server's `minOnlineBalanceDzd`, go-online and bidding fail with `403 INSUFFICIENT_WALLET_BALANCE` (`WalletErrorCodes.insufficientBalance`), which the UI turns into a top-up prompt.

### Maps & places

Google Maps via **google_maps_flutter** (`LatLng` comes from this package). The API key lives in [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) (`com.google.android.geo.API_KEY`) and [AppDelegate.swift](ios/Runner/AppDelegate.swift) (`GMSServices.provideAPIKey`). Custom markers are painted to bitmaps by [map_marker_factory.dart](lib/core/utils/map_marker_factory.dart); spherical geometry for markers, camera framing and route snapping is in [map_geo.dart](lib/core/utils/map_geo.dart). Place search, resolve and reverse geocoding go through the backend (`PlacesRepository` → `/api/passenger/places/*`). Active-ride polylines come from the shared `RideRouteCubit` + `RoutingRepository` (OSRM, see above). Turn-by-turn navigation hands off to Google Maps ([external_navigation.dart](lib/core/utils/external_navigation.dart)). Location permission/positioning via **geolocator**, with the same permission flow in `LocationPickerCubit` and `DriverLocationStreamer`.

## Backend contract & project docs

`swagger/` is authoritative for the app. The backend's source is at `/Users/mac/Development/Projects/VTC/vtc-backend`: when `swagger/` is silent or out of date, or a change depends on a server rule (validation, limits, error codes, stored fields), check the code there — it wins. [docs/features/README.md](docs/features/README.md#backend-source) says where to look. Read these before touching anything ride-related — they encode invariants the OpenAPI specs can't:
- **[epic-03-ride.md](swagger/epic-03-ride.md)** — the canonical end-to-end ride runbook (protocol, state machines, timing windows, error codes). `integration/epic-03-ride.md` is an identical copy.
- **[passenger-flow.md](swagger/passenger-flow.md)** / **[driver-flow.md](swagger/driver-flow.md)** — step-by-step flows.
- `swagger/{account,passenger,driver,websocket}.json` — OpenAPI specs per surface.
- **[integration/epic-04-wallet.md](integration/epic-04-wallet.md)** — the wallet runbook.
- [driver-registration.md](docs/features/auth/driver-registration.md) — the multi-step driver onboarding flow (`IndexedStack`, Algerian plate format `NNNNN-NNN-NN`).
- [ADMIN_CONFIG.md](ADMIN_CONFIG.md) — which values operators can change server-side (so the app must not hardcode them).

Feature docs live in [docs/features/](docs/features/README.md): one folder per feature with `README.md` (how it works), `PROGRESS.md` (checklist) and `CLEAN_CODE.md` (audit findings and what to fix). The index there also holds the audit checklist used for every feature.

Progress trackers:
- `progress/{account,passenger,driver}-progress.md` — spec-vs-implementation status per surface.
- `docs/features/<feature>/PROGRESS.md` — per-feature clean-code cleanup, with `[x]`/`[ ]` checkboxes. Tick items as they land.
- Root `WALLET_PROGRESS.md` / `NOTIFICATION_PROGRESS.md` — phased per-feature plans with `[x]`/`[ ]` checkboxes. When working on one of these features, follow its tracker and tick items as they land.

Invariants that shape client code:
- **REST is truth, WS is hints.** On every (re)connect, refetch the REST state (`GET /rides/active`, the wallet, …) and reconcile the UI, then apply live events. Cubits do this in their `statusStream` listener.
- **409s mean "your view is stale"** — refetch and re-render; don't surface them as errors.
- **Dedupe by id:** offers by `offerId`, broadcasts/requests by `rideRequestId`, rides by `rideId`. The server re-broadcasts the same `rideRequestId` ~every 10s — upsert, don't append.
- **Drive UI from server `state`** (`ride.state_changed`), not optimistic local guesses; **count down to server fields** (`expiresAt`, `arrivalWaitDeadline`) rather than hardcoded durations — the defaults are server-configurable.
- **Passenger renders the driver marker only between `ACCEPTED` and terminal state** (`COMPLETED`/`CANCELLED`).
- **Server text arrives localised** (fr/ar): error messages and notification titles/bodies are displayed as received, never translated in the app.

## Patterns to follow

- New screen: declare its path in [route_names.dart](lib/core/router/route_names.dart), add a `GoRoute` (inside the right shell) with a `BlocProvider` in [app_router.dart](lib/core/router/app_router.dart), and create the Cubit + immutable state under the feature's `presentation/cubit/`.
- New API surface: add path (and error-code) constants under `core/constants/*_api_constants.dart`, a `const` repository method calling `DioClient`, and `fromJson`/`toJson` models under the feature's `data/models/`.
- New WS event: add the wire type to `RideSocketEventType`, a sealed subclass of `RideSocketEvent`, and a parse branch in `tryParse`; consume it in whichever Cubit subscribes to `frameStream`.
- Tests: plain `flutter_test` unit tests with no mocking library. `test/` mirrors `lib/`: a test sits in the folder of the code it covers (`lib/core/utils/map_geo.dart` → `test/core/utils/map_geo_test.dart`), and a test that covers several files sits beside its main subject. Fake a repository by subclassing it and overriding methods (`class _FakeRoutingRepository extends RoutingRepository`); a repository or service that tests fake is a plain `class`, not `final class`, with a "Not `final`, so tests can extend it with a fake." doc line. The static singletons can't be injected, so keep logic you want to test in pure functions (like `resolveNotificationDestination`) or in Cubits that take repositories.
