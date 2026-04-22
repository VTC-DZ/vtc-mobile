# Driver Registration Flow

Story 8-SP — Multi-step driver registration with document upload.

## User Journey

```
Phone → OTP → Mode Selection → [Driver] → /driver-profile
  Step 1: Personal Info  (API call → saveDriverPersonalInfo)
  Step 2: Vehicle Info   (local only, no API)
  Step 3: Documents      (API call → submitDriverDocuments)
    → /driver-pending-review  (terminal, no back)
    → /driver-rejection       (terminal, shows reason + re-submit)
```

## Architecture

- **Single GoRoute** at `/driver-profile` with one `DriverRegistrationCubit`
- **`currentStep` enum** (`DriverStep.personalInfo / vehicleInfo / documents`) drives an `IndexedStack` so controllers stay alive across steps
- **Back navigation**: `PopScope(canPop: false)` — calls `cubit.goBackStep()`, and on step 1 calls `context.pop()` to return to Mode Selection

## Key Files

### New (all under `lib/features/driver/`)

| File | Purpose |
|---|---|
| `data/models/driver_document.dart` | `DriverDocument`, `UploadStatus`, `DriverDocumentType` enums |
| `presentation/cubit/driver_registration_cubit/driver_registration_state.dart` | Immutable state — all 3 steps + derived `canProceedStepN` helpers |
| `presentation/cubit/driver_registration_cubit/driver_registration_cubit.dart` | All cubit logic: validation, picking, mock upload, submit |
| `presentation/views/driver_registration_view.dart` | Shell — manages all controllers/focus nodes, `IndexedStack`, progress bar, button |
| `presentation/views/driver_pending_review_view.dart` | Terminal: "Under Review" screen |
| `presentation/views/driver_rejection_view.dart` | Terminal: rejection reason + re-submit button |
| `presentation/views/widgets/steps/driver_step1_personal_info.dart` | Step 1 UI (first name, last name, DOB, gender) |
| `presentation/views/widgets/steps/driver_step2_vehicle_info.dart` | Step 2 UI (make, model, year, color, plate, vehicle photo) |
| `presentation/views/widgets/steps/driver_step3_documents.dart` | Step 3 UI (5 document upload tiles) |
| `presentation/views/widgets/fields/driver_text_field_widget.dart` | Generic text field (same pattern as passenger profile fields) |
| `presentation/views/widgets/fields/driver_date_picker_field_widget.dart` | Tappable date picker field (min age 18 enforced via `lastDate`) |
| `presentation/views/widgets/fields/driver_year_dropdown_widget.dart` | Bottom-sheet year picker (2000 → current year) |
| `presentation/views/widgets/fields/driver_plate_field_widget.dart` | Plate field with `AlgerianPlateFormatter` (auto-inserts hyphens → `NNNNN-NNN-NN`) |
| `presentation/views/widgets/fields/driver_document_upload_tile_widget.dart` | Upload tile: idle / uploading / uploaded / error states |

### Modified

| File | Change |
|---|---|
| `pubspec.yaml` | Added `image_picker: ^1.1.2`, `file_picker: ^8.1.2` |
| `lib/core/constants/validation_patterns.dart` | Added `dzPlate` regex |
| `lib/core/constants/app_constants.dart` | Added `maxDocumentSizeBytes`, `vehicleYearFirst`, `driverMinAgeYears` |
| `lib/core/constants/app_strings.dart` | Added all driver registration strings |
| `lib/core/utils/validators.dart` | Added `plate()`, `vehicleText()` |
| `lib/core/router/route_names.dart` | Added `driverPendingReview`, `driverRejection` |
| `lib/core/router/app_router.dart` | Replaced placeholder, added 3 driver routes with `BlocProvider` |
| `lib/features/auth/data/repo/auth_repository.dart` | Added `saveDriverPersonalInfo()`, `submitDriverDocuments()` (both mock) |

## Reused Components (not recreated)

- `AppScaffold` — all driver screens
- `PrimaryButton` — shell + terminal screens
- `ProfileStepProgressBarWidget(currentStep, totalSteps)` — shell
- `ProfileFieldLabelWidget(label, badge?)` — all 3 step widgets
- `ProfileErrorBannerWidget(message)` — shell
- `ProfileGenderToggleWidget` — step 1
- `ProfileNameFieldWidget` — step 1 (first name + last name)

## State Design Summary

```dart
enum DriverStep { personalInfo, vehicleInfo, documents }
enum DriverRegistrationStatus { idle, submitting, success, failure }
enum UploadStatus { idle, uploading, uploaded, error }
enum DriverDocumentType { nationalIdFront, nationalIdBack, licenseFront, licenseBack, vehicleRegistration }
```

**Step 1 `canProceedStep1`:** firstName valid + lastName valid + DOB selected + gender selected + not submitting

**Step 2 `canProceedStep2`:** all vehicle text fields valid + year selected + plate valid + vehicle photo selected + not submitting

**Step 3 `canSubmitStep3`:** all 5 documents have `UploadStatus.uploaded` + not submitting

## Document Upload Flow (`pickDocument`)

1. Emit `UploadStatus.uploading` immediately
2. Use `image_picker` for photos; `file_picker` (JPG/PNG/PDF) for vehicle registration
3. File size check: > `AppConstants.maxDocumentSizeBytes` (5 MB) → emit `error`
4. Simulate upload: 800ms delay
5. Emit `UploadStatus.uploaded` with `filePath` + `fileName`
6. On cancel: revert to `idle`; on exception: emit `error`

## Algerian Plate Number Format

Format: `NNNNN-NNN-NN` (e.g. `12345-123-12`)

`AlgerianPlateFormatter` strips non-digits, caps at 10 digits, auto-inserts hyphens at positions 5 and 8. Regex in `ValidationPatterns.dzPlate`: `^\d{5}-\d{3}-\d{2}$`

## Pending / Not Implemented

- **Real API integration** — all repository methods are mocks with `Future.delayed`. Replace with Dio calls when backend is ready.
- **Push notification + SMS** on approval/rejection — wired from backend, not from client.
- **Driver home screen** — `/driver-home` route comes in a later story. Pending review screen currently routes to `/passenger-home`.
- **Re-submission flow** — rejection screen routes back to `/driver-profile` which recreates the cubit (fresh state). If partial pre-fill is needed, pass state via `extra`.
- **iOS `NSPhotoLibraryUsageDescription` + Android permissions** — must be added to `Info.plist` / `AndroidManifest.xml` before release.

## How to Test

1. Phone → OTP → Mode Selection → tap **Driver**
2. **Step 1:** Enter first/last name, pick DOB (under-18 blocked by date picker), select gender → Continue → 1s loading → Step 2
3. **Step 2:** Fill make/model/color, select year from sheet, type plate digits (auto-formats), tap vehicle photo → Next (instant)
4. **Step 3:** Tap each tile → gallery/file picker → uploading spinner → uploaded check → Submit → 1.5s loading → Pending Review screen
5. **Back:** Step 3 → back → Step 2 → back → Step 1 → back → Mode Selection
6. **Error paths:** Uncomment `throw` lines in `auth_repository.dart` to test error banners
7. **Rejection screen:** Navigate directly to `/driver-rejection` with `extra: 'License photo is blurry'`
