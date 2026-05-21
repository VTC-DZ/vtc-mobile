import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/validators.dart';
import '../../../data/models/gender.dart';
import '../../../data/models/passenger_profile_model.dart';
import '../../../data/repo/driver_repository.dart';
import '../../../data/models/driver_document.dart';
import 'document_pick_result.dart';
import 'driver_document_picker_service.dart';
import 'driver_profile_state.dart';

final class DriverProfileCubit extends Cubit<DriverProfileState> {
  DriverProfileCubit(
    this._driverRepo, {
    this.passengerProfile,
  }) : super(DriverProfileState(
          personalInfo: passengerProfile != null
              ? DriverPersonalInfo(
                  firstName: passengerProfile.fullName.split(' ').first,
                  lastName: passengerProfile.fullName
                      .split(' ')
                      .skip(1)
                      .join(' '),
                  gender: passengerProfile.gender,
                  dateOfBirth: passengerProfile.dateOfBirth,
                )
              : const DriverPersonalInfo(),
        ));

  final DriverRepository _driverRepo;
  final PassengerProfileModel? passengerProfile;
  final _picker = DriverDocumentPickerService();

  // ── Step 1: Personal Info ─────────────────────────────────────────────────

  void firstNameChanged(String v) => _emitPersonal(state.personalInfo
      .copyWith(firstName: v, firstNameError: Validators.name(v.trim())));
  void lastNameChanged(String v) => _emitPersonal(state.personalInfo
      .copyWith(lastName: v, lastNameError: Validators.name(v.trim())));
  void dateOfBirthSelected(DateTime date) =>
      _emitPersonal(state.personalInfo.copyWith(dateOfBirth: date));
  void genderChanged(Gender gender) =>
      _emitPersonal(state.personalInfo.copyWith(gender: gender));

  void submitStep1() {
    if (!state.canProceedStep1) return;
    emit(state.copyWith(
      currentStep: DriverStep.vehicleInfo,
      status: DriverRegistrationStatus.initial,
      errorMessage: '',
    ));
  }

  // ── Step 2: Vehicle Info ──────────────────────────────────────────────────

  void vehicleCategoryChanged(VehicleCategory category) =>
      _emitVehicle(state.vehicleInfo.copyWith(vehicleCategory: category));
  void vehicleMakeChanged(String v) => _emitVehicle(state.vehicleInfo.copyWith(
      vehicleMake: v,
      vehicleMakeError: Validators.vehicleText(v, AppStrings.fieldCarMake)));
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

  Future<void> pickInsuranceDocument(ImageSource source) async {
    emit(state.copyWith(
      vehicleInfo: state.vehicleInfo.copyWith(
        insuranceDocument: const DriverDocument(status: UploadStatus.uploading),
      ),
    ));
    final result = await _picker.pickDocument(
        DriverDocumentType.vehicleRegistration, source);
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

  Future<void> pickDocument(DriverDocumentType type, ImageSource source) async {
    emit(_setDocument(
        type, const DriverDocument(status: UploadStatus.uploading)));

    final result = await _picker.pickDocument(type, source);

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
              v.trim().isEmpty ? 'License number is required' : '',
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
    ));
    try {
      final v = state.vehicleInfo;
      final d = state.documents;
      final p = state.personalInfo;
      await _driverRepo.submitKyc(
        reqFields: {
          'firstName': p.firstName.trim(),
          'lastName': p.lastName.trim(),
          'dateOfBirth': _formatDate(p.dateOfBirth!),
          'licenseNumber': d.licenseNumber.trim(),
          'licenseExpiry': _formatDate(d.licenseExpiry!),
          'vehicleCategory': v.vehicleCategory.name.toUpperCase(),
          'vehicleModel': v.vehicleModel.trim(),
          'vehicleColor': v.vehicleColor.trim(),
          'vehiclePlate': v.plateNumber.replaceAll('-', ' ').trim(),
          'vehicleYear': v.vehicleYear!,
          'insuranceExpiry': _formatDate(v.insuranceExpiry!),
        },
        nationalIdPaths: [
          d.nationalIdFront.filePath!,
          d.nationalIdBack.filePath!,
        ],
        driverLicensePaths: [
          d.licenseFront.filePath!,
          d.licenseBack.filePath!,
        ],
        grayCardPath: d.vehicleRegistration.filePath!,
        insurancePath: v.insuranceDocument.filePath!,
        carPicturePaths: [v.vehiclePhotoPath!],
      );
      emit(state.copyWith(status: DriverRegistrationStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DriverRegistrationStatus.failure,
        errorMessage: e is String ? e : 'Submission failed. Please try again.',
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
          !state.canProceedStep1 &&
          !state.canProceedStep2) {
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

  DriverProfileState _setDocument(DriverDocumentType type, DriverDocument doc) {
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

  String _formatDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
