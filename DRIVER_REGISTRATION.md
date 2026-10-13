# Driver Registration Flow

Story 8-SP — multi-step driver registration with document upload, sent to the backend as a single KYC application.

## User Journey

```
Mode Selection → Driver               (new user: empty form)
Passenger drawer → Become a Driver    (passes the passenger profile as `extra`: pre-fills step 1)
      ↓ push
/driver-profile          DriverRegistrationView + DriverProfileCubit
  Step 1: Personal Info  (local only)
  Step 2: Vehicle Info   (local only)
  Step 3: Documents      → Submit Application → POST /api/driver/kyc/submit (multipart)
      ↓ go
/driver-status-review    DriverStatusReviewView + KycStatusCubit (GET /api/driver/kyc/status), back blocked
  PENDING  → "Continue as Passenger" → /passenger-home
  REJECTED → resubmission note + "Re-submit Documents" → /driver-profile (empty form)
  APPROVED → /driver-home
```

## Architecture

- **Single GoRoute** at `RouteNames.driverProfile` (`/driver-profile`) that provides the auth-feature `DriverProfileCubit` (`lib/features/auth/presentation/cubit/driver_profile_cubit/`) to `DriverRegistrationView`. It is unrelated to the `DriverProfileCubit` in `features/profile/driver/`, which edits an existing driver's profile.
- **`currentStep` enum** (`DriverStep.personalInfo / vehicleInfo / documents`) drives an `IndexedStack`, so each step widget and its `TextEditingController`s stay alive across steps.
- **Bottom button:** "Continue" (`submitStep1`, `proceedStep2`), then "Submit Application" (`submitStep3`) on step 3. Each is enabled by `canProceedStep1` / `canProceedStep2` / `canSubmitStep3`.
- **Moving between steps:** the dots of `ProfileStepProgressBarWidget` call `cubit.goToStep(n)`. Earlier steps are always tappable; a later step becomes tappable once the step before it is valid.
- **Back navigation:** the wizard has no `PopScope`, so system back pops `/driver-profile` and discards the form.
- **One network call:** steps 1–2 are local, and picking a document only records its local path. Everything is uploaded together by `submitStep3`.

## Key Files

### Data & state (under `lib/features/auth/`)

| File | Purpose |
|---|---|
| `data/models/driver_document.dart` | `DriverDocument` (local path + `UploadStatus`), `DriverDocumentType` |
| `data/models/kyc_status.dart` | `KycStatus` (`none / pending / approved / rejected`), parsed from the API string |
| `data/repo/driver_repository.dart` | `submitKyc` (multipart via `DioClient.postMultipart`), `getKycStatus`, plus `KycSubmitResult` / `KycStatusResult` |
| `domain/models/vehicle_color_option.dart` | The fixed color swatches; the color's name is what gets submitted |
| `presentation/cubit/driver_profile_cubit/driver_profile_state.dart` | Immutable state: one object per step (`DriverPersonalInfo`, `DriverVehicleInfo`, `DriverDocuments`) + `canProceedStepN` helpers |
| `presentation/cubit/driver_profile_cubit/driver_profile_cubit.dart` | Field changes + validation, document picking, step navigation, submit |
| `presentation/cubit/driver_profile_cubit/driver_document_picker_service.dart` | `image_picker` wrapper with the size check; returns a `DocumentPickResult` |
| `presentation/cubit/driver_profile_cubit/document_pick_result.dart` | Sealed `DocumentPickCancelled / DocumentPickSuccess / DocumentPickFailure` |
| `presentation/cubit/kyc_status_cubit/` | `KycStatusCubit`: fetches the KYC status on creation; `fetchKycStatus()` retries |

### Views (under `lib/features/auth/presentation/views/`)

| File | Purpose |
|---|---|
| `driver/driver_registration_view.dart` | Shell: progress bar, `IndexedStack`, error banner, bottom button; `go`es to status review on success |
| `driver/driver_status_review_view.dart` | KYC status screen (see below), `PopScope(canPop: false)` |
| `driver/driver_rejection_view.dart` | Standalone rejection screen at `/driver-rejection` (reason via `extra`). Nothing navigates to it; the status review screen renders rejection itself |
| `widgets/profile/driver/profile_step_progress_bar_widget.dart` | Tappable 3-step progress bar |
| `widgets/profile/driver/steps/driver_step1_personal_info.dart` | Step 1 UI (first name, last name, DOB, gender) |
| `widgets/profile/driver/steps/driver_step2_vehicle_info.dart` | Step 2 UI (type, make, model, year, color, plate, insurance expiry, vehicle photo, insurance document) |
| `widgets/profile/driver/steps/driver_step3_documents.dart` | Step 3 UI (license number + expiry, license front/back, national ID front/back, vehicle registration) |
| `widgets/profile/driver/fields/driver_text_field_widget.dart` | Generic text field |
| `widgets/profile/driver/fields/driver_date_picker_field_widget.dart` | Date picker field: birth dates end 18 years ago (`AppConstants.driverMinAgeYears`); `isFutureDate` for expiries (today → +10 years) |
| `widgets/profile/driver/fields/driver_category_dropdown_widget.dart` | Vehicle type sheet (`VehicleCategory`: car / motorcycle / van) |
| `widgets/profile/driver/fields/driver_year_dropdown_widget.dart` | Bottom-sheet year picker (current year → `AppConstants.vehicleYearFirst`, 2000) |
| `widgets/profile/driver/fields/driver_color_picker_field_widget.dart` | Bottom-sheet color swatch grid |
| `widgets/profile/driver/fields/driver_plate_field_widget.dart` | Plate field with `AlgerianPlateFormatter` |
| `widgets/profile/driver/fields/driver_document_flip_card_widget.dart` | Two-sided document card; flips to the back once the front is picked |
| `widgets/profile/driver/fields/driver_document_single_card_widget.dart` | One-sided document card (vehicle photo, insurance, vehicle registration) |

Elsewhere: `DriverApiConstants.kycSubmit` / `kycStatus` (`lib/core/constants/driver_api_constants.dart`), `ImageCompressor` (`lib/core/utils/image_compressor.dart`), `ValidationPatterns.dzPlate`, `Validators.name` / `vehicleText` / `plate`, and `AppConstants.maxDocumentSizeBytes` / `vehicleYearFirst` / `driverMinAgeYears`.

## Reused Components

- `AppScaffold`, `PrimaryButton` (`lib/shared/widgets/`): all driver onboarding screens
- `ProfileFieldLabelWidget`, `ProfileNameFieldWidget`, `ProfileGenderToggleWidget`: shared with the passenger profile form
- `ProfileErrorBannerWidget(message)`: the shell's error banner
- `showImageSourceSheet` (`lib/core/widgets/image_source_bottom_sheet.dart`): camera / gallery choice before every pick

## State Design Summary

```dart
enum DriverStep { personalInfo, vehicleInfo, documents }
enum DriverRegistrationStatus { initial, loading, success, failure }
enum UploadStatus { idle, uploading, uploaded, error }
enum DriverDocumentType { nationalIdFront, nationalIdBack, licenseFront, licenseBack, vehicleRegistration }
```

**Step 1 `canProceedStep1`:** first and last name valid (`Validators.name`, at least 2 chars) + DOB selected + gender selected + not submitting

**Step 2 `canProceedStep2`:** make, model and color valid (at least 2 chars) + year selected + plate valid + vehicle photo + insurance document + insurance expiry + not submitting

**Step 3 `canSubmitStep3`:** all 5 document photos `UploadStatus.uploaded` + license number + license expiry + not submitting

When the route gets a `PassengerProfileModel` as `extra`, the cubit pre-fills step 1: the first word of `fullName` becomes the first name, the rest the last name, plus gender and date of birth.

## Document Pick Flow (`pickDocument`)

1. Emit `UploadStatus.uploading` for that document
2. Pick an image with `image_picker` (`imageQuality: 85`) from the source chosen in `showImageSourceSheet`
3. File size check: > `AppConstants.maxDocumentSizeBytes` (5 MB) → emit `error` (`AppStrings.fileTooLarge`)
4. Wait 800 ms. This is cosmetic: nothing is sent until submit
5. Emit `UploadStatus.uploaded` with the local `filePath` + `fileName`
6. On cancel: revert to `idle`; on exception: emit `error`

The step 2 insurance document goes through the same picker (`pickInsuranceDocument`). The vehicle photo (`pickVehiclePhoto`) only stores the path, with no size check or upload status.

## Submission (`submitStep3` → `DriverRepository.submitKyc`)

A single multipart `POST /api/driver/kyc/submit` through `DioClient.postMultipart`, so it carries the bearer token and an `Idempotency-Key` like every other request. The contract is `KycSubmitRequest` in [swagger/driver.json](swagger/driver.json).

- **Text fields:** `firstName`, `lastName`, `dateOfBirth`, `licenseNumber`, `licenseExpiry`, `vehicleCategory` (`CAR` / `MOTORCYCLE` / `VAN`), `vehicleModel`, `vehicleColor`, `vehiclePlate`, `vehicleYear`, `insuranceExpiry`. Dates are `yyyy-MM-dd`.
- **Files**, each recompressed by `ImageCompressor` first (quality 70, EXIF stripped): `nationalId` ×2 (front, back), `driverLicense` ×2 (front, back), `grayCard` (vehicle registration), `insurance`, `carPictures` (the vehicle photo).
- **On success** the repository sets `AuthSession.waitingKycStatus = true` and `isNewUser = false` (so the app stops opening on mode selection), and the view `go`es to `/driver-status-review`.
- **On failure** the `ApiException` message, already localised by the backend, shows in the error banner; any other error shows a generic message.

The vehicle make is collected and validated but **not submitted**: `KycSubmitRequest` has no make field.

## KYC Status Screen

`KycStatusCubit` loads `GET /api/driver/kyc/status` when the route opens, and `DriverStatusReviewView` renders it:

| `kycStatus` | Screen |
|---|---|
| `PENDING` (or none) | "Under Review" + "Continue as Passenger" → `/passenger-home` |
| `REJECTED` | The submission's `resubmissionNote` + "Re-submit Documents" → `/driver-profile` |
| `APPROVED` | Clears `AuthSession.waitingKycStatus` and `go`es to `/driver-home` (it does not call `switchRole`) |
| request failed | Error message + Retry |

Back is blocked, so the screen is only ever reached with `go`. Besides a successful submit, it is reached from the passenger drawer's "Go to Driver" (shown once `waitingKycStatus` or `hasDriverProfile` is set; an approved driver is switched to the driver role instead) and from taps on `kyc.approved`, `kyc.rejected`, `driver.revoked` and `driver.reinstated` push notifications.

## Algerian Plate Number Format

Format: `NNNNN-NNN-NN` (e.g. `12345-123-12`)

`AlgerianPlateFormatter` strips non-digits, caps at 10 digits, and auto-inserts hyphens after the 5th and 8th digits. `ValidationPatterns.dzPlate` (`^\d{5,6}[\s-]?\d{3}[\s-]?\d{2}$`) is looser and also accepts a 6-digit first group and space or missing separators, but the formatter only produces the 10-digit hyphenated form. The plate is submitted with the hyphens replaced by spaces (`12345 123 12`).

## Known Gaps

- **Back navigation:** system back leaves the wizard and loses the form. `DriverProfileCubit.goBackStep()` exists but has no caller.
- **Re-submission starts empty:** "Re-submit Documents" recreates the cubit, so nothing from the rejected application is pre-filled.
- **PDF uploads:** the step 3 hint says "JPG, PNG or PDF", but documents are picked with `image_picker`, which only returns images.
- **Unused code:** `DriverRejectionView` (`/driver-rejection`), `DriverDocumentUploadTileWidget` (superseded by the flip and single cards), and `DriverApiConstants.registration`. Onboarding only goes through KYC submit.
- **iOS permissions:** `ios/Runner/Info.plist` has no `NSCameraUsageDescription` or `NSPhotoLibraryUsageDescription`. Add them before release, because iOS terminates an app that opens the camera without them.

## How to Test

1. Log in with a new number → Mode Selection → tap **Driver** → Continue. Or, as an existing passenger: drawer → **Become a Driver**, which pre-fills step 1.
2. **Step 1:** Enter first/last name, pick DOB (the date picker stops at 18 years ago), select gender → Continue
3. **Step 2:** Pick the vehicle type, fill make/model, pick year and color from their sheets, type plate digits (auto-formats), pick the insurance expiry, add the vehicle photo and insurance document → Continue
4. **Step 3:** Enter license number + expiry, add license front/back, national ID front/back, and vehicle registration → **Submit Application** → real multipart upload → "Under Review" screen
5. **Review outcome:** approve or reject the submission on the backend, then reopen the status screen (passenger drawer → **Go to Driver**, or tap the `kyc.*` push). Approved → driver home; rejected → reason + **Re-submit Documents**.
6. **Error paths:** a file over 5 MB shows the error state on its card; backend validation errors appear in the error banner above the button.
