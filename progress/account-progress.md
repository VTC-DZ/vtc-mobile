# Account Progress

Spec vs. app implementation status. Source: `swagger/account.json` (auth + `/api/me/*`, shared by passenger and driver).
Legend: ✅ implemented & wired to UI · ❌ not implemented · ⚠️ partial / by design

**Summary: 10/10 REST endpoints done**

Last checked: 2026-09-28

---

## REST API — `swagger/account.json`

### Auth — ✅ 5/5

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `POST /api/auth/otp/request` | `auth_repository.dart:16` → phone entry / OTP resend |
| ✅ | `POST /api/auth/otp/verify` | `auth_repository.dart:24` → OtpCubit |
| ✅ | `POST /api/auth/refresh` | `dio_client.dart:164` — 401 interceptor (transparent retry); also used by `RideSocketService` on `system.token_expiring` / close `4001` |
| ✅ | `POST /api/auth/switch-role` | `auth_repository.dart:39` and `driver_repository.dart:74` (disconnects the driver socket first) |
| ✅ | `POST /api/auth/logout` | `auth_repository.dart:53` |

### Me — ✅ 5/5

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `GET /api/me/profile` | `profile_repository.dart:11` → passenger home/profile; `driver_repository.dart:84` → driver profile |
| ✅ | `PUT /api/me/profile` | `profile_repository.dart:57` → PassengerProfileEditCubit |
| ✅ | `PATCH /api/me/email` | `profile_repository.dart:18` → EmailEditCubit |
| ✅ | `POST /api/me/phone/request` | `profile_repository.dart:27` → PhoneEditCubit (OTP to new number) |
| ✅ | `POST /api/me/phone/confirm` | `profile_repository.dart:35` → PhoneEditCubit; stores the re-issued tokens via `AuthSession.setTokens` |
