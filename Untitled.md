# Notifications: front-end integration guide

Oct 10, 2026 · @Aimed Eddine Touati

The backend now stores notifications and delivers them in three ways: a push to the phone, a list over REST, and a live WebSocket message. Everything is on `master`.

## What exists

| Piece | For whom | Where |
| --- | --- | --- |
| Push notifications (Firebase) | Passengers, drivers | Register the phone with `POST /api/me/push-token` |
| Notification list with read / unread | Passengers, drivers | `GET /api/me/notifications`, plus unread count, mark one read, mark all read |
| Live "new notification" message | Passengers, drivers | `notification.created` on `/ws/passenger` and `/ws/driver` |
| Notification list and live message, no push | Admins | `/api/admin/notifications` and `notification.created` on `/ws/admin` |

## Main points

- **The list is the truth.** A push or a WebSocket message can be missed, so reload the list and the unread count when the app opens.
- **Text arrives ready.** Title and body come in the user's language (French or Arabic). Nothing to translate in the app.
- **Register the push token after every login.** Logout deletes it on the server.
- **Not every push is in the list.** The list keeps what is worth reading later: ride completed or cancelled, wallet movements, KYC and account decisions. Trip progress, new ride requests and offers are push only.
- **Each item has an `eventKey` and a `data` map of ids**, to pick an icon and open the right screen.
- **Existing WebSocket messages did not change.** `notification.created` is the only new one.

## Where the details are

In the backend repo: `docs/api/account.md` (mobile calls), `docs/api/admin.md` (dashboard calls), `docs/api/websocket.md` (live messages) and `docs/modules/06-notification.md` (how it all works). The calls can be tried in Swagger at `/swagger-ui.html`.
