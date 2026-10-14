import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rapidoo/core/constants/app_strings.dart';
import 'package:rapidoo/core/errors/api_exception.dart';
import 'package:rapidoo/core/models/gender.dart';
import 'package:rapidoo/features/auth/data/driver_document_picker_service.dart';
import 'package:rapidoo/features/auth/data/kyc_repository.dart';
import 'package:rapidoo/features/auth/data/models/document_pick_result.dart';
import 'package:rapidoo/features/auth/data/models/document_source.dart';
import 'package:rapidoo/features/auth/data/models/driver_document.dart';
import 'package:rapidoo/features/auth/data/models/kyc_status_result.dart';
import 'package:rapidoo/features/auth/data/models/kyc_submission.dart';
import 'package:rapidoo/features/auth/presentation/cubit/driver_registration_cubit/driver_registration_cubit.dart';
import 'package:rapidoo/features/auth/presentation/cubit/driver_registration_cubit/driver_registration_state.dart';
import 'package:rapidoo/features/profile/shared/data/models/kyc_status.dart';
import 'package:rapidoo/features/profile/shared/data/models/passenger_profile_model.dart';
import 'package:rapidoo/features/profile/shared/data/profile_repository.dart';
import 'package:rapidoo/features/ride/shared/models/shared_ride_models.dart';

PassengerProfileModel _profile({
  required String fullName,
  bool hasDriverProfile = false,
}) =>
    PassengerProfileModel(
      id: 'u-1',
      fullName: fullName,
      gender: Gender.female,
      dateOfBirth: DateTime(1995, 5, 2),
      status: 'ACTIVE',
      hasDriverProfile: hasDriverProfile,
      profileCompleted: true,
      activeRole: 'PASSENGER',
      hasPassengerProfile: true,
      savedAddressCount: 0,
      driverKycStatus: KycStatus.none,
    );

/// Returns [next] for every document pick and a fixed vehicle photo.
class _FakePicker extends DriverDocumentPickerService {
  _FakePicker() : super.withPicker(ImagePicker());

  DocumentPickResult next = const DocumentPickCancelled();

  @override
  Future<DocumentPickResult> pickDocument(DocumentSource source) async => next;

  @override
  Future<String?> pickVehiclePhoto(ImageSource source) async => '/docs/car.jpg';
}

/// Records every submission and reports [progress] while sending; fails
/// while [error] is set.
class _FakeKycRepository extends KycRepository {
  final submitted = <KycSubmission>[];
  List<double> progress = const [];
  Object? error;

  @override
  Future<KycSubmitResult> submitKyc(
    KycSubmission submission, {
    void Function(double fraction)? onProgress,
  }) async {
    submitted.add(submission);
    progress.forEach(onProgress ?? (_) {});
    final failure = error;
    if (failure != null) throw failure;
    return const KycSubmitResult(submissionId: 's-1', status: 'PENDING');
  }
}

/// Records the account saves; fails while [error] is set.
class _FakeProfileRepository extends ProfileRepository {
  final saved = <({String fullName, Gender gender, DateTime dateOfBirth})>[];
  Object? error;

  @override
  Future<PassengerProfileModel> saveProfile({
    required String fullName,
    required Gender gender,
    required DateTime dateOfBirth,
  }) async {
    saved.add((fullName: fullName, gender: gender, dateOfBirth: dateOfBirth));
    final failure = error;
    if (failure != null) throw failure;
    return _profile(fullName: fullName);
  }
}

void main() {
  late _FakePicker picker;
  late _FakeKycRepository repository;
  late _FakeProfileRepository profiles;
  late DriverRegistrationCubit cubit;

  setUp(() {
    picker = _FakePicker();
    repository = _FakeKycRepository();
    profiles = _FakeProfileRepository();
    cubit = DriverRegistrationCubit(repository, profiles, picker: picker);
  });
  tearDown(() => cubit.close());

  void fillStep1() {
    cubit
      ..firstNameChanged('Youcef')
      ..lastNameChanged('Benali')
      ..dateOfBirthSelected(DateTime(1990, 1, 1))
      ..genderChanged(Gender.male);
  }

  Future<void> pick(DriverDocumentType type, String path) {
    picker.next = DocumentPickSuccess(path: path, name: path.split('/').last);
    return cubit.pickDocument(type, DocumentSource.gallery);
  }

  Future<void> fillStep2() async {
    cubit
      ..vehicleCategoryChanged(VehicleCategory.van)
      ..vehicleModelChanged('Hiace')
      ..vehicleColorChanged('White')
      ..plateNumberChanged('12345-123-16')
      ..vehicleYearChanged(2018)
      ..insuranceExpiryChanged(DateTime(2027, 3, 1));
    await cubit.pickVehiclePhoto(ImageSource.gallery);
    picker.next = const DocumentPickSuccess(
        path: '/docs/insurance.jpg', name: 'insurance.jpg');
    await cubit.pickInsuranceDocument(DocumentSource.file);
  }

  Future<void> fillStep3() async {
    await pick(DriverDocumentType.nationalIdFront, '/docs/id-front.jpg');
    await pick(DriverDocumentType.nationalIdBack, '/docs/id-back.jpg');
    await pick(DriverDocumentType.licenseFront, '/docs/license-front.jpg');
    await pick(DriverDocumentType.licenseBack, '/docs/license-back.jpg');
    await pick(
        DriverDocumentType.vehicleRegistration, '/docs/registration.jpg');
    cubit
      ..licenseNumberChanged('123456789')
      ..licenseExpiryChanged(DateTime(2030, 1, 1));
  }

  group('step navigation', () {
    test('a valid step 1 with an invalid step 2 cannot jump to step 3', () {
      fillStep1();
      expect(cubit.state.canProceedStep1, isTrue);
      expect(cubit.state.canProceedStep2, isFalse);

      cubit.goToStep(3);

      expect(cubit.state.currentStep, DriverStep.personalInfo);
    });

    test('an invalid step 1 cannot move forward at all', () {
      cubit.goToStep(2);
      expect(cubit.state.currentStep, DriverStep.personalInfo);

      cubit.goToStep(3);
      expect(cubit.state.currentStep, DriverStep.personalInfo);
    });

    test('a valid step 1 can move to step 2 and back', () {
      fillStep1();

      cubit.goToStep(2);
      expect(cubit.state.currentStep, DriverStep.vehicleInfo);

      cubit.goToStep(1);
      expect(cubit.state.currentStep, DriverStep.personalInfo);
    });

    test('back goes one step back and stops at step 1', () {
      fillStep1();
      cubit.goToStep(2);

      cubit.goBackStep();
      expect(cubit.state.currentStep, DriverStep.personalInfo);

      cubit.goBackStep();
      expect(cubit.state.currentStep, DriverStep.personalInfo);
    });
  });

  group('hasChanges', () {
    test('is false for a wizard opened empty or only pre-filled', () {
      final prefilled = DriverRegistrationCubit(
        repository,
        profiles,
        passengerProfile: _profile(fullName: 'Amina Benali'),
        picker: picker,
      );
      addTearDown(prefilled.close);

      expect(cubit.hasChanges, isFalse);
      expect(prefilled.hasChanges, isFalse);
    });

    test('is true once something is entered on any step', () async {
      cubit.firstNameChanged('Youcef');
      expect(cubit.hasChanges, isTrue);

      final other = DriverRegistrationCubit(repository, profiles, picker: picker);
      addTearDown(other.close);
      await other.pickVehiclePhoto(ImageSource.camera);
      expect(other.hasChanges, isTrue);
    });
  });

  test('submitting needs every step valid, not only the documents', () {
    final state = DriverRegistrationState(
      documents: DriverDocuments(
        nationalIdFront: const DriverDocument(status: UploadStatus.uploaded),
        nationalIdBack: const DriverDocument(status: UploadStatus.uploaded),
        licenseFront: const DriverDocument(status: UploadStatus.uploaded),
        licenseBack: const DriverDocument(status: UploadStatus.uploaded),
        vehicleRegistration:
            const DriverDocument(status: UploadStatus.uploaded),
        licenseNumber: '123456789',
        licenseExpiry: DateTime(2030, 1, 1),
      ),
    );

    expect(state.documents.allUploaded, isTrue);
    expect(state.canSubmitStep3, isFalse);
  });

  test('name errors name the field they belong to', () {
    cubit
      ..firstNameChanged('')
      ..lastNameChanged('');

    expect(cubit.state.personalInfo.firstNameError, 'First Name is required');
    expect(cubit.state.personalInfo.lastNameError, 'Last Name is required');
  });

  test('pre-fills step 1 from the passenger profile', () async {
    final prefilled = DriverRegistrationCubit(
      repository,
      profiles,
      passengerProfile: _profile(fullName: 'Youcef Ben Ali'),
      picker: picker,
    );
    addTearDown(prefilled.close);

    final info = prefilled.state.personalInfo;
    expect(info.firstName, 'Youcef');
    expect(info.lastName, 'Ben Ali');
    expect(info.gender, Gender.female);
    expect(info.dateOfBirth, DateTime(1995, 5, 2));
  });

  group('step 1 saves the account (AUTH-006)', () {
    test('for a new applicant, then moves on to step 2', () async {
      fillStep1();

      await cubit.submitStep1();

      expect(profiles.saved.single, (
        fullName: 'Youcef Benali',
        gender: Gender.male,
        dateOfBirth: DateTime(1990, 1, 1),
      ));
      expect(cubit.state.currentStep, DriverStep.vehicleInfo);
    });

    test('not once a driver profile exists, as the server locks it', () async {
      final resubmission = DriverRegistrationCubit(
        repository,
        profiles,
        passengerProfile:
            _profile(fullName: 'Youcef Benali', hasDriverProfile: true),
        savesAccount: false,
        picker: picker,
      );
      addTearDown(resubmission.close);

      await resubmission.submitStep1();

      expect(profiles.saved, isEmpty);
      expect(resubmission.state.currentStep, DriverStep.vehicleInfo);
    });

    test('a failed save stays on step 1 with the server message', () async {
      profiles.error = const ApiException(message: 'Nom invalide');
      fillStep1();

      await cubit.submitStep1();

      expect(cubit.state.currentStep, DriverStep.personalInfo);
      expect(cubit.state.status, DriverRegistrationStatus.failure);
      expect(cubit.state.errorMessage, 'Nom invalide');
    });
  });

  group('documents', () {
    test('a picked document is stored with its path', () async {
      await pick(DriverDocumentType.licenseFront, '/docs/license-front.jpg');

      final document = cubit.state.documents.licenseFront;
      expect(document.isUploaded, isTrue);
      expect(document.filePath, '/docs/license-front.jpg');
    });

    test('a PDF is kept as picked, to be sent as a PDF', () async {
      await pick(
          DriverDocumentType.vehicleRegistration, '/docs/registration.pdf');

      final document = cubit.state.documents.vehicleRegistration;
      expect(document.isUploaded, isTrue);
      expect(document.isPdf, isTrue);
      expect(cubit.state.documents.licenseFront.isPdf, isFalse);
    });

    test('a failed pick keeps the reason for the card to show', () async {
      picker.next =
          const DocumentPickFailure(errorMessage: AppStrings.fileTooLarge);

      await cubit.pickDocument(
          DriverDocumentType.licenseFront, DocumentSource.camera);

      final document = cubit.state.documents.licenseFront;
      expect(document.status, UploadStatus.error);
      expect(document.errorMessage, AppStrings.fileTooLarge);
    });

    test('a cancelled pick resets the card', () async {
      await cubit.pickDocument(
          DriverDocumentType.licenseFront, DocumentSource.gallery);

      expect(cubit.state.documents.licenseFront.status, UploadStatus.idle);
    });
  });

  group('submit', () {
    Future<void> fillAllSteps() async {
      fillStep1();
      await fillStep2();
      await fillStep3();
      expect(cubit.state.canSubmitStep3, isTrue);
    }

    test('sends every step as one KYC submission', () async {
      await fillAllSteps();

      await cubit.submitStep3();

      expect(
        repository.submitted.single,
        KycSubmission(
          firstName: 'Youcef',
          lastName: 'Benali',
          dateOfBirth: DateTime(1990, 1, 1),
          licenseNumber: '123456789',
          licenseExpiry: DateTime(2030, 1, 1),
          vehicleCategory: VehicleCategory.van,
          vehicleModel: 'Hiace',
          vehicleColor: 'White',
          vehiclePlate: '12345-123-16',
          vehicleYear: 2018,
          insuranceExpiry: DateTime(2027, 3, 1),
          nationalIdPaths: const ['/docs/id-front.jpg', '/docs/id-back.jpg'],
          driverLicensePaths: const [
            '/docs/license-front.jpg',
            '/docs/license-back.jpg',
          ],
          grayCardPath: '/docs/registration.jpg',
          insurancePath: '/docs/insurance.jpg',
          carPicturePaths: const ['/docs/car.jpg'],
        ),
      );
      expect(cubit.state.status, DriverRegistrationStatus.success);
    });

    test('carries the upload progress while sending', () async {
      await fillAllSteps();
      repository.progress = const [0.5, 0.504, 1.0];
      final percents = expectLater(
        cubit.stream.map((state) => state.submitPercent),
        emitsInOrder([0, 50, 100]),
      );

      await cubit.submitStep3();

      await percents;
    });

    test('shows the server message when the submission fails', () async {
      await fillAllSteps();
      repository.error = const ApiException(message: 'Plaque invalide');

      await cubit.submitStep3();

      expect(cubit.state.status, DriverRegistrationStatus.failure);
      expect(cubit.state.errorMessage, 'Plaque invalide');
    });

    test('does nothing while the application is incomplete', () async {
      fillStep1();

      await cubit.submitStep3();

      expect(repository.submitted, isEmpty);
    });
  });
}
