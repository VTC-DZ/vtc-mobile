# Driver Progress

Spec vs. app implementation status. Source: `swagger/driver.json` + `swagger/websocket.json` (driver surface), cross-checked with `swagger/epic-03-ride.md` §5/§13 and `swagger/driver-flow.md`.
Legend: ✅ implemented & wired to UI · ❌ not implemented · ⚠️ partial / by design

**Summary: 21/21 REST endpoints done · WS: 9/9 server events handled, 0 missing · 2/2 upstream · +6 wallet events (outside websocket.json)**

Last checked: 2026-09-29

---

## REST API — `swagger/driver.json`

### Profile — ✅ 2/2

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `PUT /api/driver/profile` (update profile) | `driver_profile_repository.dart:10` → driver profile screen "Preferences" (`acceptsFemaleOnly`) toggle |
| ✅ | `PUT /api/driver/profile/service-types` | `driver_service_types_repository.dart:10` → driver profile screen |

### Location — ✅ 1/1

| Status | Endpoint | Notes |
|--------|----------|-------|
| ✅ | `POST /api/driver/location` | REST fallback in `driver_location_streamer.dart:107` — used on each 15s tick whenever the driver socket isn't connected (`reconnecting` / `disconnected` / `failed`) or the WS send fails. WS `driver.location` stays the primary transport |

### KYC — ✅ 2/2

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `POST /api/driver/kyc/submit` (multipart) | `driver_repository.dart:18` → registration wizard step 3 |
| ✅ | `GET /api/driver/kyc/status` | `driver_repository.dart:91` → KycStatusCubit |

### Availability — ✅ 2/2

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `POST /api/driver/availability/online` | `driver_availability_repository.dart:7` → online toggle |
| ✅ | `POST /api/driver/availability/offline` | `driver_availability_repository.dart:15` |

### Rides — ✅ 9/9

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `GET /api/driver/rides/available` | `driver_ride_repository.dart:11` → available-rides feed |
| ✅ | `POST /api/driver/rides/{rideRequestId}/bid` | `driver_ride_repository.dart:18` → card / request details sheet |
| ✅ | `POST /api/driver/rides/{rideId}/arrived` | `driver_ride_repository.dart:26` |
| ✅ | `POST /api/driver/rides/{rideId}/start` | `driver_ride_repository.dart:34` |
| ✅ | `POST /api/driver/rides/{rideId}/complete` | `driver_ride_repository.dart:42` |
| ✅ | `POST /api/driver/rides/{rideId}/cancel` | `driver_ride_repository.dart:50` |
| ✅ | `GET /api/driver/rides/active` | `driver_ride_repository.dart:59` |
| ✅ | `GET /api/driver/rides` (history, paginated + filters) | `driver_ride_repository.dart:67` |
| ✅ | `GET /api/driver/rides/{rideId}` (ride detail) | `driver_ride_repository.dart:91` → ride detail screen (history card tap) |

### Wallet — ✅ 5/5

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `GET /api/driver/wallet` (balance + gate) | `wallet_repository.dart:16` → WalletCubit |
| ✅ | `GET /api/driver/wallet/transactions` (paginated) | `wallet_repository.dart:21` |
| ✅ | `GET /api/driver/wallet/topups` | `wallet_repository.dart:35` (+ `getPendingTopUp` at `:57`) |
| ✅ | `POST /api/driver/wallet/topups` (multipart, receipt) | `wallet_repository.dart:67` → top-up sheet |
| ✅ | `POST /api/driver/wallet/topups/{id}/cancel` | `wallet_repository.dart:97` |

---

## WebSocket — `swagger/websocket.json` (`/ws/driver`)

### Server → driver

| Status | Event | Notes |
|--------|-------|-------|
| ✅ | `ride.broadcast` | `available_rides_cubit.dart:89` — upserted by `rideRequestId` (`_upsertRide`, `:115`) |
| ✅ | `ride.broadcast_cancelled` | `available_rides_cubit.dart:91` |
| ✅ | `offer.accepted` | `available_rides_cubit.dart:93` — bid won |
| ✅ | `ride.state_changed` | `driver_active_ride_cubit.dart:23` — refetches active ride |
| ✅ | `ride.cancelled` | `driver_active_ride_cubit.dart:25` |
| ✅ | `system.token_expiring` | Handled centrally: `ride_socket_service.dart:180-192` → REST refresh + upstream `system.auth_refresh` |
| ✅ | `offer.countered` | Reserved / not emitted in v1. Parsed as `OfferCountered` (`ride_socket_event.dart:323`); `available_rides_cubit.dart:110` reconciles via `loadAvailableRides()` since the pending bid is stale. No counter-offer UI (epic-03 §5) |
| ✅ | `offer.rejected` | `available_rides_cubit.dart:104` → `_endBid` — card removed + reason toast in `driver_home_shell.dart` (`EXPLICIT_REJECT` / `SIBLING_ACCEPTED` / `REQUEST_CANCELLED`); silent for `DRIVER_OFFLINE` or when no local bid is on record |
| ✅ | `offer.expired` | `available_rides_cubit.dart:106` → `_endBid` — card removed + "Your bid expired" toast. Live bids are tracked in `AvailableRidesState.pendingBids` (from the bid `BidResponse`); the card shows "Bid sent" and counts down to the bid's own `expiresAt` |

### Server → driver — wallet events (not in `websocket.json`; from the wallet epic)

| Status | Event | Notes |
|--------|-------|-------|
| ✅ | `wallet.topup_approved` / `wallet.topup_rejected` / `wallet.balance_low` | `wallet_cubit.dart:135-144` |
| ✅ | `wallet.commission_charged` / `wallet.penalty_charged` / `wallet.balance_adjusted` | Via `WalletBalanceEvent` catch-all, `wallet_cubit.dart:152` |

### Client → server

| Status | Event | Notes |
|--------|-------|-------|
| ✅ | `driver.location` | `driver_location_streamer.dart:98` — every 15s while online, plus an immediate send on reconnect |
| ✅ | `system.auth_refresh` | `ride_socket_service.dart:264` — replies to token-expiring warning |

---

## Integration checklist — `epic-03-ride.md` §13

| Status | Item | Notes |
|--------|------|-------|
| ✅ | WS with `Authorization` header; refresh on `system.token_expiring` | `ride_socket_service.dart` |
| ⚠️ | On (re)connect, refetch and reconcile | `AvailableRidesCubit._onStatus` reloads `/rides/available` (`available_rides_cubit.dart:82`) and prunes `pendingBids` for closed requests / past-deadline bids; `DriverActiveRideCubit` has **no** `statusStream` listener, so a reconnect mid-trip doesn't refetch `/rides/active` |
| ✅ | Reconnect backoff 1→2→4→8→16 s | `WebSocketConstants.backoffSteps`, `ride_socket_service.dart:245` |
| ✅ | Dedupe broadcasts by `rideRequestId` | `_upsertRide` |
| ✅ | Drive UI from `ride.state_changed` | Refetch on every state change |
| ⚠️ | Count down to server fields | ✅ request `expiresAt` and bid `expiresAt` (`expiry_indicators.dart`); ❌ `arrivalWaitDeadline` / `inProgressDeadline` are parsed in `driver_ride_models.dart` but not shown |
| ⚠️ | 409s → refetch, not failure (bid races) | `ApiException.isConflict` exists (`api_exception.dart:26`) but no ride cubit uses it — only wallet flows treat 409 as stale view |
| ✅ | Stream `driver.location`; REST `/location` fallback | `driver_location_streamer.dart` — WS while connected, REST while down |

---

## Dead code (in app, not in spec)

- ❌ `POST /api/driver/registration` — constant at `driver_api_constants.dart:7`, never referenced; onboarding goes through KYC submit.

## Feature gaps (not in spec either)

- ❌ Ratings — no submit endpoint for passengers to rate drivers (or vice versa); not in `driver.json` either.
- ❌ Earnings screen — no dedicated endpoint; earnings are inferred from wallet transactions/commission events.

## Non-spec external dependencies

- ⚠️ Road routing (active-ride polylines) calls the public **OSRM demo server** (`routing_api_constants.dart`, `routing_repository.dart`) — no SLA, not allowed for production traffic; needs a backend routing endpoint before release.
- ✅ "Navigate" button hands off to an external maps app (`external_navigation.dart`) — no API involved.
