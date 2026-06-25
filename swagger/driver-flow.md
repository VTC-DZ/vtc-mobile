# Driver Flow — Step by Step

Based on `websocket.json` and `epic-03-ride.md`.

---

## Step 1: Connect to WebSocket

Connect to `/ws/driver` with `Authorization: Bearer <JWT>` (token must have `activeRole=DRIVER`).

Then immediately call `GET /api/driver/rides/active` to reconcile any state you missed while offline.

```
GET /ws/driver HTTP/1.1
Upgrade: websocket
Authorization: Bearer <accessToken>
```

---

## Step 2: Go Online

```
POST /api/driver/availability/online
```

You can't receive broadcasts or bid while offline. Going offline later auto-cancels all your active bids — passengers and driver both get `offer.rejected: DRIVER_OFFLINE`.

---

## Step 3: Stream Your Location (continuously)

Send upstream over the WS socket:

```json
{ "type": "driver.location", "payload": { "lat": 36.7, "lng": 3.04, "capturedAt": "2026-06-25T10:00:00Z" } }
```

- Rate limit: max **20 msg/s**
- This is what the matching engine uses to find you — keep streaming while online
- If the socket drops, fall back to `POST /api/driver/location` (REST, same shape)

---

## Step 4: Listen for `ride.broadcast`

The server pushes this when a passenger request matches you:

```json
{
  "type": "ride.broadcast",
  "payload": {
    "rideRequestId": "uuid",
    "pickup": { "lat": 36.7, "lng": 3.04, "address": "..." },
    "dropoff": { "lat": 36.8, "lng": 3.05, "address": "..." },
    "proposedFare": 750,
    "femaleOnly": false,
    "serviceType": "STANDARD",
    "vehicleCategory": "SEDAN",
    "expiresAt": "2026-06-25T10:05:00Z"
  }
}
```

- Same `rideRequestId` can arrive **multiple times** (re-broadcast sweeper runs every 10s) → dedupe by `rideRequestId`
- Show the card with a countdown to `expiresAt`

---

## Step 5: Bid or Ignore

If you want the ride:

```
POST /api/driver/rides/{rideRequestId}/bid
Body: { "fare": 700 }
```

Response:
```json
{ "offerId": "uuid", "fare": 700, "round": 1, "direction": "DRIVER_TO_PASSENGER", "expiresAt": "..." }
```

**Fare rules:**
- Must be within **±50%** of the passenger's proposed fare
- Floor: **100 DZD**, ceiling: **50 000 DZD**
- Out of range → `400 FARE_OUT_OF_BOUNDS` (response includes allowed min/max)

**Bid limits:**
- Max **3 active bids** at once across different requests
- Exceeding → `409 MAX_BIDS_REACHED`

If you ignore → nothing to do, the card disappears when `ride.broadcast_cancelled` arrives or it expires.

---

## Step 6: Wait for Bid Outcome

After bidding, you get one of:

| Event | Meaning | What to do |
|---|---|---|
| `offer.accepted` | Passenger accepted your bid → you won the ride | Navigate to active ride screen |
| `offer.rejected { reason: EXPLICIT_REJECT }` | Passenger refused your bid | Remove the card |
| `offer.rejected { reason: SIBLING_ACCEPTED }` | Passenger picked another driver | Remove the card |
| `offer.rejected { reason: REQUEST_CANCELLED }` | Request was cancelled | Remove the card |
| `offer.expired` | 30s passed, bid timed out | Remove the card |
| `ride.broadcast_cancelled` | The whole request is gone | Remove the card |

---

## Step 7: Fetch the Active Ride

After receiving `offer.accepted`, fetch the full trip details:

```
GET /api/driver/rides/active
```

Response:
```json
{
  "rideId": "uuid",
  "passenger": { ... },
  "pickup": { "lat", "lng", "address" },
  "dropoff": { "lat", "lng", "address" },
  "finalFare": 700,
  "state": "ACCEPTED"
}
```

Navigate the driver to the pickup location. Keep streaming `driver.location` — the passenger can now see you on the map.

---

## Step 8: Confirm Arrival

When you physically arrive at the pickup point:

```
POST /api/driver/rides/{rideId}/arrived
```

Response includes `arrivalWaitDeadline` — passenger has **5 minutes** (default) to show up.

- Passenger receives `ride.state_changed: ARRIVED`
- Continue streaming your location

> You can cancel here as `PASSENGER_NO_SHOW` **only after** `arrivalWaitDeadline` passes.
> Trying before → `409 ARRIVAL_GRACE_NOT_ELAPSED`.

---

## Step 9: Start the Ride

When the passenger is in the car:

```
POST /api/driver/rides/{rideId}/start
```

- Ride moves to `IN_PROGRESS`
- Passenger receives `ride.state_changed: IN_PROGRESS`
- Keep streaming location — passenger sees you live on the map until the trip ends

---

## Step 10: Complete the Ride

When you reach the destination:

```
POST /api/driver/rides/{rideId}/complete
```

Response:
```json
{ "state": "COMPLETED", "finalFare": 700 }
```

- Stop streaming location
- Both sides receive `ride.state_changed: COMPLETED`

---

## Cancellation Rules

| Ride State | Can Driver Cancel? | Allowed Reasons |
|---|---|---|
| `ACCEPTED` | Yes | `DRIVER_TOO_FAR`, `DRIVER_VEHICLE_ISSUE` |
| `ARRIVED` | Yes, after `arrivalWaitDeadline` | `PASSENGER_NO_SHOW` |
| `IN_PROGRESS` | No | — |

```
POST /api/driver/rides/{rideId}/cancel
Body: { "reason": "DRIVER_TOO_FAR", "note": "optional" }
```

---

## Summary

```
Connect WS → Go Online → Stream GPS → Receive broadcast → Bid → Win →
Fetch ride → Arrived → Start → Complete
```

## Token Refresh (mid-ride)

When you receive `system.token_expiring` (~2 min before expiry):

1. `POST /api/auth/refresh` with your `refreshToken`
2. Send over WS: `{ "type": "system.auth_refresh", "payload": { "token": "<new accessToken>" } }`
3. Server replies: `{ "type": "system.auth_refresh", "payload": { "ok": true } }`

Socket stays open. If you miss the window, server closes with code `4001` — reconnect with a fresh token.

## Key Constraints

| Rule | Value |
|---|---|
| Max concurrent active bids | 3 |
| Bid expiry | 30 s |
| Fare band | ±50% of proposed (floor 100, ceiling 50 000 DZD) |
| GPS rate limit | 20 msg/s |
| Must-arrive window after `ACCEPTED` | 120 s (then system cancels) |
| Passenger no-show grace after `ARRIVED` | 300 s |
| WS reconnect backoff | 1 → 2 → 4 → 8 → 16 s |
