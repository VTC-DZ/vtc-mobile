# Account Progress

Spec vs. app implementation status. Source: `swagger/account.json` (auth + `/api/me/*`, shared by passenger and driver).
Legend: ✅ implemented & wired to UI · ❌ not implemented · ⚠️ partial / by design

**Summary: 10/10 REST endpoints done**

Last checked: 2026-10-13 (after auth Phase 7, checked against the backend source; see docs/features/auth/)

---

## REST API — `swagger/account.json`

### Auth — ✅ 5/5

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `POST /api/auth/otp/request` | `auth/data/auth_repository.dart:19` → phone entry / OTP resend (E.164); `429 otp_locked` locks the OTP screen |
| ✅ | `POST /api/auth/otp/verify` | `auth/data/auth_repository.dart:27` → OtpCubit; stores the tokens and onboarding flags, then registers the device for push. Only `401 otp_invalid` counts toward the lock |
| ✅ | `POST /api/auth/refresh` | `dio_client.dart:141` — 401 interceptor (transparent retry); also used by `RideSocketService` on `system.token_expiring` / close `4001` |
| ✅ | `POST /api/auth/switch-role` | `auth/data/auth_repository.dart:51` `switchRole(ActiveRole)`; switching to passenger disconnects the driver socket first |
| ✅ | `POST /api/auth/logout` | `auth/data/auth_repository.dart:66`, then `SessionTeardown.run()` (which also clears the notifications on screen). Sends `{pushToken}` when this device has one, otherwise `{}` |

### Me — ✅ 5/5

| Status | Endpoint | Implementation |
|--------|----------|----------------|
| ✅ | `GET /api/me/profile` | `profile/shared/data/profile_repository.dart:16` → passenger home/profile, and the KYC status screen for a rejected or revoked application (pre-fill, `driver.requiresRekyc`); `:23` `getDriverProfile` → driver home |
| ✅ | `PUT /api/me/profile` | `profile/shared/data/profile_repository.dart:64` → PassengerProfileCubit (onboarding), the driver wizard's step 1 (first application only) and PassengerProfileEditCubit |
| ✅ | `PATCH /api/me/email` | `profile/shared/data/profile_repository.dart:30` → EmailEditCubit |
| ✅ | `POST /api/me/phone/request` | `profile/shared/data/profile_repository.dart:39` → PhoneEditCubit (OTP to new number) |
| ✅ | `POST /api/me/phone/confirm` | `profile/shared/data/profile_repository.dart:47` → PhoneEditCubit; stores the re-issued tokens via `AuthSession.setTokens` |
