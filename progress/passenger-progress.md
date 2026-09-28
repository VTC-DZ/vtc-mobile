# Passenger Progress

Spec vs. app implementation status. Source: `swagger/passenger.json` + `swagger/websocket.json` (passenger surface), cross-checked with `swagger/epic-03-ride.md` §5/§13 and `swagger/passenger-flow.md` §13.
Legend: ✅ implemented & wired to UI · ❌ not implemented · ⚠️ partial / by design

**Summary: 15/15 REST endpoints done · WS: 6/12 server events handled, 3 by design, 3 missing (10 in websocket.json + 2 epic-03-only)**

Last checked: 2026-09-28

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
| ✅ | `POST /api/passenger/rides` (create) | `passenger_ride_repository.dart:10` |
| ✅ | `GET /api/passenger/rides/active` | `passenger_ride_repository.dart:58` |
| ✅ | `GET /api/passenger/rides/{rideRequestId}/offers` | `passenger_ride_repository.dart:18` → waiting-offers screen (REST poll + WS trigger) |
| ✅ | `POST /api/passenger/rides/{rideRequestId}/offers/{offerId}/accept` | `passenger_ride_repository.dart:25` |
| ✅ | `POST /api/passenger/rides/{rideRequestId}/offers/{offerId}/refuse` | `passenger_ride_repository.dart:36` |
| ✅ | `POST /api/passenger/rides/{rideRequestId}/cancel` | `passenger_ride_repository.dart:47` |
| ✅ | `GET /api/passenger/rides` (history, paginated + filters) | `passenger_ride_repository.dart:64` |
| ✅ | `GET /api/passenger/rides/{rideRequestId}` (ride detail) | `passenger_ride_repository.dart:64` → ride detail screen (history card tap); addresses/service type/cancel reason come from the tapped history item since the response omits them |

---

## WebSocket — `swagger/websocket.json` (`/ws/passenger`)

### Server → passenger

| Status | Event | Notes |
|--------|-------|-------|
| ✅ | `offer.created` | `waiting_offers_cubit.dart:30` — triggers REST repoll (offers replaced wholesale → deduped by `offerId`) |
| ✅ | `ride.state_changed` | `passenger_active_ride_cubit.dart:70` |
| ✅ | `ride.cancelled` | `passenger_active_ride_cubit.dart:72` |
| ✅ | `driver.location` | `passenger_active_ride_cubit.dart:74` — live driver position |
| ✅ | `system.token_expiring` | Handled centrally: `ride_socket_service.dart:180-192` → REST refresh + upstream `system.auth_refresh` (`:264`) |
| ✅ | `system.auth_refresh` (ack) | Nothing to do on ack; refresh already applied locally |
| ⚠️ | `offer.accepted` | Parsed, not consumed — by design: the passenger triggers accept via REST and moves on from the response (`WaitingOffersCubit.acceptOffer` → `AcceptStatus.success`) |
| ⚠️ | `offer.expired` | Parsed, not consumed — covered client-side: `offer_card.dart:49-66` counts down to `expiresAt` and calls `WaitingOffersCubit.removeOffer` (`waiting_offers_view.dart:111`) |
| ⚠️ | `offer.countered` | **Reserved / not emitted in v1** (epic-03 §5: "Don't build counter-offer UI"). Not parsed — correct for now |
| ❌ | `offer.rejected` | Parsed in `ride_socket_event.dart:283` but no cubit consumes it — e.g. a `DRIVER_OCCUPIED` bid stays on screen until the next repoll/expiry |

### Server → passenger — listed in `epic-03-ride.md` §5 only (not in `websocket.json`)

| Status | Event | Notes |
|--------|-------|-------|
| ❌ | `ride.requested` | Parsed (`ride_socket_event.dart:200`) but unused — create confirmation comes from the REST response instead |
| ❌ | `ride.request_cancelled` | Parsed (`ride_socket_event.dart:215`) but unused — a `NO_DRIVERS`/`TIMEOUT` auto-cancel isn't surfaced on the waiting-offers screen |

### Client → server

| Status | Event | Notes |
|--------|-------|-------|
| ✅ | `system.auth_refresh` | `ride_socket_service.dart:264` — the only upstream allowed on the passenger socket |

---

## Integration checklist — `passenger-flow.md` §13 / `epic-03-ride.md` §13

| Status | Item | Notes |
|--------|------|-------|
| ✅ | WS with `Authorization` header; refresh on `system.token_expiring` | `ride_socket_service.dart` |
| ⚠️ | On (re)connect, `GET /rides/active` and reconcile | `WaitingOffersCubit` repolls on `connected` (`waiting_offers_cubit.dart:37`); `PassengerActiveRideCubit` has **no** `statusStream` listener, so a reconnect mid-trip doesn't refetch |
| ✅ | Reconnect backoff 1→2→4→8→16 s | `WebSocketConstants.backoffSteps`, `ride_socket_service.dart:245` |
| ✅ | Dedupe offers by `offerId` | Offers list replaced from REST on each poll |
| ✅ | Drive UI from `ride.state_changed` | `passenger_active_ride_cubit.dart:70` |
| ✅ | Count down to server `expiresAt` | Offer cards (`offer_card.dart:49`) + request (`passenger_home_view.dart:70`) |
| ⚠️ | `409 RIDE_ALREADY_ACCEPTED` → refetch, not failure | `ApiException.isConflict` exists (`api_exception.dart:26`) but no ride cubit uses it — 409s surface as `actionFailure` toasts |
| ✅ | Driver marker only `ACCEPTED` → terminal | Active-ride map |
| ✅ | Cancel allowed through `ARRIVED`, blocked in `IN_PROGRESS` | `canCancel` in `passenger_active_ride_view.dart:121` |
| ❌ | Post-cancel cooldown countdown before a new ride | Not implemented |

---

## Dead code (in app, not in spec)

- ❌ `POST /api/passenger/rides/{rideRequestId}/counter-offer` — constant at `ride_api_constants.dart:15`, never called, and endpoint doesn't exist in `passenger.json` (counter-offers are reserved for a future engine).

## Feature gaps (not in spec either)

- ❌ Ratings — no submit/list endpoint in spec or app; `driverRatingAvg` is display-only on offer cards.

## Non-spec external dependencies

- ⚠️ Road routing (active-ride polylines) calls the public **OSRM demo server** (`routing_api_constants.dart`, `routing_repository.dart`) — no SLA, not allowed for production traffic; needs a backend routing endpoint before release.
