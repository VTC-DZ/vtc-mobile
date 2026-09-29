# Passenger Progress

Spec vs. app implementation status. Source: `swagger/passenger.json` + `swagger/websocket.json` (passenger surface), cross-checked with `swagger/epic-03-ride.md` §5/§13 and `swagger/passenger-flow.md` §13.
Legend: ✅ implemented & wired to UI · ❌ not implemented · ⚠️ partial / by design

**Summary: 15/15 REST endpoints done · WS: 11/12 server events handled, 1 missing (10 in websocket.json + 2 epic-03-only)**

Last checked: 2026-09-29

---

## REST API — `swagger/passenger.json`

### Places — ✅ 3/3 (Nominatim replaced in `8697a03`)

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `GET /api/passenger/places/search` | `places_repository.dart:12` → `LocationPickerCubit.search` (`location_picker_cubit.dart:129`), session token + position bias |
| ✅ | `GET /api/passenger/places/reverse-geocode` | `places_repository.dart:38` → map tap / initial position (`location_picker_cubit.dart:106`) |
| ✅ | `GET /api/passenger/places/{placeId}` | `places_repository.dart:31` → resolve on result pick (`location_picker_cubit.dart:158`) |

### Addresses — ✅ 4/4

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `GET /api/passenger/addresses` | `address_repository.dart:8` → SavedPlacesCubit + location picker favorites |
| ✅ | `POST /api/passenger/addresses` | `address_repository.dart:16` → address create screen |
| ✅ | `PUT /api/passenger/addresses/{id}` | `address_repository.dart:24` → address edit screen |
| ✅ | `DELETE /api/passenger/addresses/{id}` | `address_repository.dart:32` → delete confirm on card |

### Rides — ✅ 8/8

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `POST /api/passenger/rides` (create) | `passenger_ride_repository.dart:11` |
| ✅ | `GET /api/passenger/rides/active` | `passenger_ride_repository.dart:59` |
| ✅ | `GET /api/passenger/rides/{rideRequestId}/offers` | `passenger_ride_repository.dart:19` → waiting-offers screen (REST poll + WS trigger) |
| ✅ | `POST /api/passenger/rides/{rideRequestId}/offers/{offerId}/accept` | `passenger_ride_repository.dart:26` |
| ✅ | `POST /api/passenger/rides/{rideRequestId}/offers/{offerId}/refuse` | `passenger_ride_repository.dart:37` |
| ✅ | `POST /api/passenger/rides/{rideRequestId}/cancel` | `passenger_ride_repository.dart:48` |
| ✅ | `GET /api/passenger/rides` (history, paginated + filters) | `passenger_ride_repository.dart:72` |
| ✅ | `GET /api/passenger/rides/{rideRequestId}` (ride detail) | `passenger_ride_repository.dart:64` → ride detail screen (history card tap); addresses/service type/cancel reason come from the tapped history item since the response omits them |

---

## WebSocket — `swagger/websocket.json` (`/ws/passenger`)

### Server → passenger

| Status | Event | Notes |
|--------|-------|-------|
| ✅ | `offer.created` | `waiting_offers_cubit.dart:32` — triggers REST repoll (offers replaced wholesale → deduped by `offerId`) |
| ✅ | `ride.state_changed` | `passenger_active_ride_cubit.dart:123` |
| ✅ | `ride.cancelled` | `passenger_active_ride_cubit.dart:125` |
| ✅ | `driver.location` | `passenger_active_ride_cubit.dart:127` — live driver position |
| ✅ | `system.token_expiring` | Handled centrally: `ride_socket_service.dart:180-192` → REST refresh + upstream `system.auth_refresh` (`:264`) |
| ✅ | `system.auth_refresh` (ack) | Nothing to do on ack; refresh already applied locally |
| ✅ | `offer.accepted` | `waiting_offers_cubit.dart:41` → `_markAccepted` (`:147`) — covers an accept from another device or a lost REST accept response. Our own REST accept, a poll that sees an `ACCEPTED` offer (`:87`) and the reconnect `_reconcile` (`:103`) go through the same once-only helper, so whichever signal lands first navigates to the active ride |
| ✅ | `offer.expired` | `waiting_offers_cubit.dart:54` → `removeOffer`. The card's `ExpiryProgressBar` countdown (`offer_card.dart:66-71`, `onExpired` → `waiting_offers_view.dart:125` → `removeOffer`) remains as a fallback |
| ✅ | `offer.countered` | Reserved / not emitted in v1. Parsed as `OfferCountered` (`ride_socket_event.dart:121`, class `:323`); `waiting_offers_cubit.dart:59` drops the superseded `previousOfferId` card and repolls REST. No counter-offer UI (epic-03 §5). ⚠️ Spec mismatch: `websocket.json` names the field `parentOfferId`, epic-03 §5 says `previousOfferId` — the parser only reads `previousOfferId`, so the stale card is only dropped under the epic-03 name (REST repoll still reconciles) |
| ✅ | `offer.rejected` | `waiting_offers_cubit.dart:51` → `removeOffer` — clears stale `DRIVER_OCCUPIED` / `DRIVER_OFFLINE` bids before the passenger can tap Accept (no-op after the passenger's own refuse) |

### Server → passenger — listed in `epic-03-ride.md` §5 only (not in `websocket.json`)

| Status | Event | Notes |
|--------|-------|-------|
| ❌ | `ride.requested` | Parsed (`ride_socket_event.dart:211`) but unused — create confirmation comes from the REST response instead |
| ✅ | `ride.request_cancelled` | `waiting_offers_cubit.dart:45` → `_markRequestEnded` (`:128`) → phase `expired`; the view (`waiting_offers_view.dart:46`) toasts the `NO_DRIVERS` / `TIMEOUT` reason and goes home. A frame missed while offline is caught by the reconnect `_reconcile` (`:103`), which ends the request when `/rides/active` no longer lists it |

### Client → server

| Status | Event | Notes |
|--------|-------|-------|
| ✅ | `system.auth_refresh` | `ride_socket_service.dart:264` — the only upstream allowed on the passenger socket |

---

## Integration checklist — `passenger-flow.md` §13 / `epic-03-ride.md` §13

| Status | Item | Notes |
|--------|------|-------|
| ✅ | WS with `Authorization` header; refresh on `system.token_expiring` | `ride_socket_service.dart` |
| ✅ | On (re)connect, `GET /rides/active` and reconcile | `WaitingOffersCubit._reconcile` (`waiting_offers_cubit.dart:103`, on `connected` at `:70`) resolves the request against `/rides/active` — accepted → active ride, gone/cancelled → ended — then repolls offers. `PassengerActiveRideCubit._onStatus` (`passenger_active_ride_cubit.dart:28`) → `_reconcile` (`:41`) silently refetches the ride (stage + driver position) once a ride is on screen; if it ended while offline, the ride detail (`:58`) tells completed from cancelled |
| ✅ | Reconnect backoff 1→2→4→8→16 s | `WebSocketConstants.backoffSteps`, `ride_socket_service.dart:245` |
| ✅ | Dedupe offers by `offerId` | Offers list replaced from REST on each poll |
| ✅ | Drive UI from `ride.state_changed` | `passenger_active_ride_cubit.dart:115` |
| ✅ | Count down to server `expiresAt` | Offer cards (`offer_card.dart:66`) + request (`passenger_home_view.dart:70`) |
| ✅ | `409 RIDE_ALREADY_ACCEPTED` → refetch, not failure | Passenger 409s go through `ApiException.isConflict` → `_reconcile` with no error toast: accept (`waiting_offers_cubit.dart:178`), refuse (`:211`, also drops the card), request cancel (`:242`) and active-ride cancel (`passenger_active_ride_cubit.dart:109`). `409 RIDE_ALREADY_ACTIVE` on create (`ride_request_cubit.dart:52`) routes home and re-runs `PassengerHomeCubit.checkActiveRide`, which resumes the live request/ride (`ride_request_view.dart:115`) |
| ✅ | Driver marker only `ACCEPTED` → terminal | Active-ride map |
| ✅ | Cancel allowed through `ARRIVED`, blocked in `IN_PROGRESS` | `canCancel` in `passenger_active_ride_view.dart:130` |
| ✅ | Post-cancel cooldown countdown before a new ride | Reactive: `429 RIDE_CREATE_COOLDOWN` (`ride_request_cubit.dart:57`) → `_startCooldown` (`:69`) counts down from the `Retry-After` header (`ApiException.retryAfter`, parsed in `DioClient._retryAfter`) or the 30 s spec default; the submit button reads "Try again in Ns" and stays disabled until it hits 0 (`ride_request_view.dart:291`). The server exposes no cooldown field, so nothing is shown before the first 429 |
| ✅ | Don't build counter-offer UI (epic-03 §13) | None exists; `offer.countered` only reconciles the list |
| ✅ | Wave-2 nullable fields render gracefully (epic-03 §13) | `etaSeconds` is `int?` (`passenger_ride_models.dart:111`); `distanceMeters` / `durationSeconds` / route geometry nullable (`passenger_ride_detail_models.dart:37-40`) |

---

## Dead code (in app, not in spec)

- ❌ `POST /api/passenger/rides/{rideRequestId}/counter-offer` — constant at `ride_api_constants.dart:15`, never called, and endpoint doesn't exist in `passenger.json` (counter-offers are reserved for a future engine).

## Feature gaps (not in spec either)

- ❌ Ratings — no submit/list endpoint in spec or app; `driverRatingAvg` is display-only on offer cards.

## Non-spec external dependencies

- ⚠️ Road routing (active-ride polylines) calls the public **OSRM demo server** (`routing_api_constants.dart`, `routing_repository.dart`) — no SLA, not allowed for production traffic; needs a backend routing endpoint before release.
