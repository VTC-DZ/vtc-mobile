import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/models/gender.dart';
import '../../../../profile/shared/data/models/passenger_profile_model.dart';
import '../../../../profile/shared/data/profile_repository.dart';
import '../../../../ride/shared/models/shared_ride_models.dart';
import '../../../data/kyc_repository.dart';
import '../../../data/models/driver_document.dart';
import '../../../data/models/document_pick_result.dart';
import '../../../data/models/document_source.dart';
import '../../../data/models/kyc_submission.dart';
import '../../../data/driver_document_picker_service.dart';
import 'driver_registration_state.dart';

final class DriverRegistrationCubit extends Cubit<DriverRegistrationState> {
  /// [passengerProfile] pre-fills step 1 ("Become a driver" from the
  /// passenger drawer, or a re-submission). [savesAccount] says whether
  /// step 1 saves the account (see [_savesAccount]). [picker] is replaceable
  /// for tests.
  DriverRegistrationCubit(
    this._kycRepository,
    this._profileRepository, {
    PassengerProfileModel? passengerProfile,
    bool savesAccount = true,
    DriverDocumentPickerService? picker,
  })  : _picker = picker ?? DriverDocumentPickerService(),
        _savesAccount = savesAccount,
        super(DriverRegistrationState(
          personalInfo: passengerProfile != null
              ? DriverPersonalInfo.fromPassengerProfile(passengerProfile)
              : const DriverPersonalInfo(),
        )) {
    _openedWith = state.personalInfo;
  }

  final KycRepository _kycRepository;
  final ProfileRepository _profileRepository;
  final DriverDocumentPickerService _picker;

  /// Whether step 1 saves the account. The KYC request carries no gender, so
  /// step 1 stores name, gender and date of birth on the account, as user
  /// story AUTH-006 asks. Only a first application does: once a driver
  /// profile exists the server locks those fields (`403`).
  final bool _savesAccount;

  /// Step 1 as the wizard opened: empty, or pre-filled.
  late final DriverPersonalInfo _openedWith;

  /// Whether leaving now would lose something the user entered. A pre-filled
  /// step 1 on its own doesn't count.
  bool get hasChanges =>
      state.personalInfo != _openedWith ||
      state.vehicleInfo != const DriverVehicleInfo() ||
      state.documents != const DriverDocuments();

  // ── Step 1: Personal Info ─────────────────────────────────────────────────

  void firstNameChanged(String v) => _emitPersonal(state.personalInfo.copyWith(
      firstName: v,
      firstNameError:
          Validators.name(v.trim(), field: AppStrings.fieldFirstName)));
  void lastNameChanged(String v) => _emitPersonal(state.personalInfo.copyWith(
      lastName: v,
      lastNameError:
          Validators.name(v.trim(), field: AppStrings.fieldLastName)));
  void dateOfBirthSelected(DateTime date) =>
      _emitPersonal(state.personalInfo.copyWith(dateOfBirth: date));
  void genderChanged(Gender gender) =>
      _emitPersonal(state.personalInfo.copyWith(gender: gender));

  Future<void> submitStep1() async {
    if (!state.canProceedStep1) return;
    if (_savesAccount) {
      emit(state.copyWith(
        status: DriverRegistrationStatus.loading,
        errorMessage: '',
      ));
      final info = state.personalInfo;
      try {
        await _profileRepository.saveProfile(
          fullName: info.fullName,
          gender: info.gender!,
          dateOfBirth: info.dateOfBirth!,
        );
      } catch (e) {
        emit(state.copyWith(
          status: DriverRegistrationStatus.failure,
          errorMessage: ApiException.messageOf(e,
              fallback: AppStrings.personalInfoSaveFailed),
        ));
        return;
      }
    }
    emit(state.copyWith(
      currentStep: DriverStep.vehicleInfo,
      status: DriverRegistrationStatus.initial,
      errorMessage: '',
    ));
  }

  // ── Step 2: Vehicle Info ──────────────────────────────────────────────────

  void vehicleCategoryChanged(VehicleCategory category) =>
      _emitVehicle(state.vehicleInfo.copyWith(vehicleCategory: category));
  void vehicleModelChanged(String v) => _emitVehicle(state.vehicleInfo.copyWith(
      vehicleModel: v,
      vehicleModelError: Validators.vehicleText(v, AppStrings.fieldCarModel)));
  void vehicleColorChanged(String v) => _emitVehicle(state.vehicleInfo.copyWith(
      vehicleColor: v,
      vehicleColorError: Validators.vehicleText(v, AppStrings.fieldColor)));
  void plateNumberChanged(String v) => _emitVehicle(state.vehicleInfo
      .copyWith(plateNumber: v, plateNumberError: Validators.plate(v)));
  void vehicleYearChanged(int year) =>
      _emitVehicle(state.vehicleInfo.copyWith(vehicleYear: year));
  void insuranceExpiryChanged(DateTime date) =>
      _emitVehicle(state.vehicleInfo.copyWith(insuranceExpiry: date));

  Future<void> pickVehiclePhoto(ImageSource source) async {
    final path = await _picker.pickVehiclePhoto(source);
    if (path != null) {
      emit(state.copyWith(
        vehicleInfo: state.vehicleInfo.copyWith(vehiclePhotoPath: path),
      ));
    }
  }

  Future<void> pickInsuranceDocument(DocumentSource source) async {
    emit(state.copyWith(
      vehicleInfo: state.vehicleInfo.copyWith(
        insuranceDocument: const DriverDocument(status: UploadStatus.uploading),
      ),
    ));
    final result = await _picker.pickDocument(source);
    switch (result) {
      case DocumentPickCancelled():
        emit(state.copyWith(
          vehicleInfo: state.vehicleInfo.copyWith(
            insuranceDocument: const DriverDocument(),
          ),
        ));
      case DocumentPickSuccess(:final path, :final name):
        emit(state.copyWith(
          vehicleInfo: state.vehicleInfo.copyWith(
            insuranceDocument: DriverDocument(
              filePath: path,
              fileName: name,
              status: UploadStatus.uploaded,
            ),
          ),
        ));
      case DocumentPickFailure(:final errorMessage):
        emit(state.copyWith(
          vehicleInfo: state.vehicleInfo.copyWith(
            insuranceDocument: DriverDocument(
              status: UploadStatus.error,
              errorMessage: errorMessage,
            ),
          ),
        ));
    }
  }

  void proceedStep2() {
    if (!state.canProceedStep2) return;
    emit(state.copyWith(
      currentStep: DriverStep.documents,
      status: DriverRegistrationStatus.initial,
      errorMessage: '',
    ));
  }

  // ── Step 3: Documents ─────────────────────────────────────────────────────

  Future<void> pickDocument(
      DriverDocumentType type, DocumentSource source) async {
    emit(_setDocument(
        type, const DriverDocument(status: UploadStatus.uploading)));

    final result = await _picker.pickDocument(source);

    switch (result) {
      case DocumentPickCancelled():
        emit(_setDocument(type, const DriverDocument()));
      case DocumentPickSuccess(:final path, :final name):
        emit(_setDocument(
          type,
          DriverDocument(
              filePath: path, fileName: name, status: UploadStatus.uploaded),
        ));
      case DocumentPickFailure(:final errorMessage):
        emit(_setDocument(
          type,
          DriverDocument(
              status: UploadStatus.error, errorMessage: errorMessage),
        ));
    }
  }

  void licenseNumberChanged(String v) => emit(state.copyWith(
        documents: state.documents.copyWith(
          licenseNumber: v,
          licenseNumberError:
              v.trim().isEmpty ? AppStrings.licenseNumberRequired : '',
        ),
      ));

  void licenseExpiryChanged(DateTime date) => emit(state.copyWith(
        documents: state.documents.copyWith(licenseExpiry: date),
      ));

  Future<void> submitStep3() async {
    if (!state.canSubmitStep3) return;
    emit(state.copyWith(
      status: DriverRegistrationStatus.loading,
      errorMessage: '',
      submitPercent: 0,
    ));
    try {
      await _kycRepository.submitKyc(
        _buildSubmission(),
        onProgress: _submitProgressed,
      );
      emit(state.copyWith(status: DriverRegistrationStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DriverRegistrationStatus.failure,
        errorMessage: ApiException.messageOf(e,
            fallback: AppStrings.submissionFailed),
      ));
    }
  }

  // ── Step navigation ───────────────────────────────────────────────────────

  void goToStep(int oneBased) {
    final target = DriverStep.values[oneBased - 1];
    if (target == state.currentStep) return;
    if (target.index > state.currentStep.index) {
      if (target == DriverStep.vehicleInfo && !state.canProceedStep1) {
        return;
      }
      if (target == DriverStep.documents &&
          (!state.canProceedStep1 || !state.canProceedStep2)) {
        return;
      }
    }
    emit(state.copyWith(
      currentStep: target,
      status: DriverRegistrationStatus.initial,
      errorMessage: '',
    ));
  }

  void goBackStep() {
    switch (state.currentStep) {
      case DriverStep.vehicleInfo:
        emit(state.copyWith(
          currentStep: DriverStep.personalInfo,
          status: DriverRegistrationStatus.initial,
          errorMessage: '',
        ));
      case DriverStep.documents:
        emit(state.copyWith(
          currentStep: DriverStep.vehicleInfo,
          status: DriverRegistrationStatus.initial,
          errorMessage: '',
        ));
      case DriverStep.personalInfo:
        break;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Whole percents only, so the many send callbacks become a few states.
  void _submitProgressed(double fraction) {
    if (isClosed) return;
    emit(state.copyWith(
        submitPercent: (fraction * 100).floor().clamp(0, 100)));
  }

  void _emitPersonal(DriverPersonalInfo info) => emit(state.copyWith(
        status: DriverRegistrationStatus.initial,
        errorMessage: '',
        personalInfo: info,
      ));

  void _emitVehicle(DriverVehicleInfo info) => emit(state.copyWith(
        status: DriverRegistrationStatus.initial,
        errorMessage: '',
        vehicleInfo: info,
      ));

  DriverRegistrationState _setDocument(DriverDocumentType type, DriverDocument doc) {
    return state.copyWith(
      documents: state.documents.copyWith(
        nationalIdFront:
            type == DriverDocumentType.nationalIdFront ? doc : null,
        nationalIdBack: type == DriverDocumentType.nationalIdBack ? doc : null,
        licenseFront: type == DriverDocumentType.licenseFront ? doc : null,
        licenseBack: type == DriverDocumentType.licenseBack ? doc : null,
        vehicleRegistration:
            type == DriverDocumentType.vehicleRegistration ? doc : null,
      ),
    );
  }

  /// The application as the API takes it. Only called once
  /// [DriverRegistrationState.canSubmitStep3] holds, so every field is set.
  KycSubmission _buildSubmission() {
    final p = state.personalInfo;
    final v = state.vehicleInfo;
    final d = state.documents;
    return KycSubmission(
      firstName: p.firstName,
      lastName: p.lastName,
      dateOfBirth: p.dateOfBirth!,
      licenseNumber: d.licenseNumber,
      licenseExpiry: d.licenseExpiry!,
      vehicleCategory: v.vehicleCategory,
      vehicleModel: v.vehicleModel,
      vehicleColor: v.vehicleColor,
      vehiclePlate: v.plateNumber,
      vehicleYear: v.vehicleYear!,
      insuranceExpiry: v.insuranceExpiry!,
      nationalIdPaths: [d.nationalIdFront.filePath!, d.nationalIdBack.filePath!],
      driverLicensePaths: [d.licenseFront.filePath!, d.licenseBack.filePath!],
      grayCardPath: d.vehicleRegistration.filePath!,
      insurancePath: v.insuranceDocument.filePath!,
      carPicturePaths: [v.vehiclePhotoPath!],
    );
  }
}
