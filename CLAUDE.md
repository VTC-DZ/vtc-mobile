# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`khfif_drif` — an inDrive-style ride-hailing app for Algeria (whole-DZD fares, OTP auth, passenger-vs-driver negotiation, OTP/KYC flows). Flutter app, Dart SDK `^3.5.0`. Built against a Spring backend REST + raw-WebSocket "VTC" API.

## Common commands

```bash
flutter pub get          # install/refresh dependencies
flutter run              # run on the selected device (use -d <deviceId>)
flutter analyze          # static analysis (flutter_lints; the project relies on this — run before considering work done)
flutter test             # run widget/unit tests (NOTE: test/ is currently empty — no tests exist yet)
flutter build apk        # or: flutter build ios / flutter build web
```

Backend target is `http://localhost:8080` ([api_constants.dart](lib/core/constants/api_constants.dart)). For the **Android emulator**, change `baseUrl` to `http://10.0.2.2:8080` (the emulator maps the host loopback to `10.0.2.2`). The WS base URL is derived from this REST base automatically ([ws_url.dart](lib/core/network/ws_url.dart)) — do not introduce a separate `wsBaseUrl` constant.

## Architecture

### Feature-sliced layout (`lib/`)

- **`core/`** — cross-cutting infrastructure. Notable subfolders: `network/` (DioClient, RideSocketService, DriverLocationStreamer), `session/` (AuthSession), `router/` (go_router config + RouteNames), `storage/` (SecureStorageHelper), `constants/` (per-surface API path constants, app strings, validation patterns), `theme/`, `errors/`, `utils/` (jwt_decoder, validators, phone/image helpers), `widgets/`.
- **`features/`** — vertical slices. Each feature mirrors the passenger/driver split: `features/auth`, `features/home/{passenger,driver}`, `features/ride/{passenger,driver,shared}`, `features/profile/{passenger,driver,shared}`, `features/saved_places`. Inside a slice the convention is `data/` (repositories + models) and `presentation/` (`cubit/` + `views/` + `views/widgets/`).
- **`shared/widgets/`** — cross-feature reusable widgets.

### Infrastructure is static singletons (no DI container)

`DioClient`, `RideSocketService`, `DriverLocationStreamer`, and `AuthSession` are `final class` with a private constructor and `static` members. Repositories are `const`-constructible value types (e.g. `const PassengerRideRepository()`) that depend on these singletons statically. When wiring a new screen, repositories are passed into the Cubit in the route's `BlocProvider` (see [app_router.dart](lib/core/router/app_router.dart)) — they are not registered anywhere.

### State & navigation

- **State:** `flutter_bloc` (mostly **Cubits**, some Blocs) + `equatable` for immutable states. A `MyBlocObserver` ([observer.dart](lib/core/helper/observer.dart)) logs every create/change/error/close — this is intentionally verbose for debugging; expect noisy console output in debug.
- **Navigation:** `go_router`. Routes live as string constants in [route_names.dart](lib/core/router/route_names.dart) — always reference `RouteNames.*`, never raw strings. The passenger and driver home areas are **`ShellRoute`s** whose builders provide shell-scoped Cubits (e.g. `PassengerHomeCubit`, `DriverHomeCubit`, `WebSocketConnectionCubit`, `AvailableRidesCubit`) that survive navigation between sibling screens. The startup route is decided at boot by `AuthSession.resolveInitialRoute()` (based on persisted tokens/role flags).
- **Responsive sizing:** `flutter_screenutil` (design size in `AppConstants.designWidth/Height`). Use `.h/.w/.sp`. Fonts come from `google_fonts` (Plus Jakarta Sans + Inter) — no TTF assets needed.

### Networking — `DioClient` ([dio_client.dart](lib/core/network/dio_client.dart))

All HTTP goes through `DioClient.get/post/put/delete/patch/postMultipart`. Interceptors (read top-to-bottom):
1. **Auth:** attaches `Authorization: Bearer <accessToken>` from `AuthSession.accessToken` if present.
2. **Idempotency:** auto-attaches a hand-rolled RFC-4122-v4 `Idempotency-Key` header (`_uuid()`) to every POST/PUT/DELETE **except** paths under `/api/auth/*`. This makes retries safe — do not strip it.
3. **401 refresh:** on a 401 (unless already refreshing or no refresh token), calls `/api/auth/refresh`, stores new tokens, and transparently retries the original request. On refresh failure it clears the session and routes to `/` (phone entry).
4. **Logging** (debug only): full request/response bodies.

Errors are normalized by `_handleDioError`: it parses the API error envelope `{error:{code,message,details}}` ([api_error_model.dart](lib/core/errors/api_error_model.dart)) and returns the `message` string. **401/403 with an API message also clear the session and force re-login.** Repositories therefore `throw` (string) on failure; Cubits catch and map to a failure state.

### Realtime — raw WebSocket, NOT STOMP ([ride_socket_service.dart](lib/core/network/ride_socket_service.dart))

> ⚠️ The transport is a **plain WebSocket** (`IOWebSocketChannel`). There is no STOMP, no SockJS, no topic subscriptions. Do **not** add a STOMP client library. Open one socket per role (`/ws/passenger`, `/ws/driver`); the JWT goes in the `Authorization` header of the upgrade request, and `/ws/driver` additionally requires `activeRole == DRIVER`.

`RideSocketService` owns the connection lifecycle only:
- `connect(ActiveRole)`, `disconnect()`, `send(envelope)`, and auto-reconnect with exponential backoff (`1→2→4→8→16s`, in `WebSocketConstants.backoffSteps`).
- Interprets close codes `1000`/`4001`/`4002`/`4003`/`4004` ([web_socket_constants.dart](lib/core/constants/web_socket_constants.dart)).
- **Token refresh without dropping the socket:** intercepts `system.token_expiring` frames, REST-refreshes the token, and sends `system.auth_refresh` upstream. If the window is missed (close `4001`), it refreshes then reconnects fresh.

It exposes two streams that feature code consumes:
- `statusStream` → `RideSocketStatus {disconnected, connecting, connected, reconnecting, failed}`. Mirrored to UI by `WebSocketConnectionCubit`.
- `frameStream` → raw envelope JSON strings (unparsed by design). Feature Cubits subscribe here, decode with `RideSocketEvent.tryParse` ([ride_socket_event.dart](lib/features/ride/driver/data/models/ride_socket_event.dart)), and switch on the typed event. Example: [available_rides_cubit.dart](lib/features/ride/driver/presentation/cubit/available_rides_cubit/available_rides_cubit.dart).

`DriverLocationStreamer` ([driver_location_streamer.dart](lib/core/network/driver_location_streamer.dart)) streams GPS upstream as `driver.location` envelopes on a timer while armed (armed by `DriverAvailabilityCubit` on go-online); it pauses/resumes with the socket's status automatically.

### Auth & session — `AuthSession` ([auth_session.dart](lib/core/session/auth_session.dart))

Static singleton holding access/refresh tokens plus flags (`isNewUser`, `waitingKycStatus`, `hasDriverProfile`, `lastRole`), all persisted to `flutter_secure_storage` via `SecureStorageHelper`. `setTokens` is the single entry point that updates both memory and storage. The JWT payload (claims include `activeRole`, `kycVerified`, `hasDriverProfile`) is decoded by `JwtDecoder` + `TokenPayload` ([token_payload.dart](lib/core/models/token_payload.dart)).

### Maps

OSM-based via **flutter_map** + **latlong2** (no Google Maps API key). Location permission/positioning via **geolocator**. The same permission flow is reused by `LocationPickerCubit` and `DriverLocationStreamer`.

## Backend contract — `swagger/` is authoritative

The `swagger/` directory holds the integration runbook and field-level specs. When touching anything ride-related, read these first — they encode invariants Swagger can't:
- **[epic-03-ride.md](swagger/epic-03-ride.md)** — the canonical end-to-end runbook (protocol, state machines, timing windows, error codes, checklist).
- **[passenger-flow.md](swagger/passenger-flow.md)** / **[driver-flow.md](swagger/driver-flow.md)** — step-by-step flows.
- **[DRIVER_REGISTRATION.md](DRIVER_REGISTRATION.md)** — the multi-step driver onboarding flow (single `DriverRegistrationCubit` + `IndexedStack`, Algerian plate format `NNNNN-NNN-NN`, mock repository methods).

Invariants that shape client code:
- **REST is truth, WS is hints.** On every (re)connect, refetch `GET /rides/active` and reconcile the UI, then apply live events. Cubits do this in their `statusStream` listener (see `_onStatus` → `loadAvailableRides`).
- **409s mean "your view is stale"** — refetch and re-render; don't surface them as hard errors.
- **Dedupe by id:** offers by `offerId`, broadcasts/requests by `rideRequestId`, rides by `rideId`. The server re-broadcasts the same `rideRequestId` ~every 10s — upsert, don't append.
- **Drive UI from server `state`** (`ride.state_changed`), not optimistic local guesses; **count down to server fields** (`expiresAt`, `arrivalWaitDeadline`) rather than hardcoded durations — the defaults are server-configurable.
- **Passenger renders the driver marker only between `ACCEPTED` and terminal state** (`COMPLETED`/`CANCELLED`).

## Patterns to follow

- New screen: declare its path in [route_names.dart](lib/core/router/route_names.dart), add a `GoRoute`/`ShellRoute` entry with a `BlocProvider` in [app_router.dart](lib/core/router/app_router.dart), and create the Cubit + immutable state under the feature's `presentation/cubit/`.
- New API surface: add path constants under `core/constants/*_api_constants.dart`, a `const` repository method calling `DioClient`, and `fromJson`/`toJson` models under the feature's `data/models/`.
- New WS event: add the wire type to `RideSocketEventType`, a sealed subclass of `RideSocketEvent`, and a parse branch in `tryParse`; consume it in whichever Cubit subscribes to `frameStream`.
- Many repositories are still **mocks** with `Future.delayed` (notably driver registration/KYC per the docs above) — wire them to Dio when the backend is ready rather than assuming they hit the network.
