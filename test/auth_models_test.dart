import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/models/auth_tokens_model.dart';
import 'package:rapidoo/features/auth/data/models/kyc_status_result.dart';
import 'package:rapidoo/features/auth/data/models/kyc_submission.dart';
import 'package:rapidoo/core/models/gender.dart';
import 'package:rapidoo/features/profile/shared/data/models/kyc_status.dart';
import 'package:rapidoo/features/profile/shared/data/models/passenger_profile_model.dart';
import 'package:rapidoo/features/ride/shared/models/shared_ride_models.dart';

void main() {
  group('AuthTokensModel.fromJson', () {
    test('reads the tokens and flags', () {
      final tokens = AuthTokensModel.fromJson({
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'isNewUser': true,
        'profileCompleted': true,
        'hasDriverProfile': true,
      });

      expect(tokens.accessToken, 'access');
      expect(tokens.refreshToken, 'refresh');
      expect(tokens.isNewUser, isTrue);
      expect(tokens.profileCompleted, isTrue);
      expect(tokens.hasDriverProfile, isTrue);
    });

    test('defaults missing flags to false, as a refresh response may omit them',
        () {
      final tokens = AuthTokensModel.fromJson({
        'accessToken': 'access',
        'refreshToken': 'refresh',
      });

      expect(tokens.isNewUser, isFalse);
      expect(tokens.profileCompleted, isFalse);
      expect(tokens.hasDriverProfile, isFalse);
    });
  });

  group('PassengerProfileModel.fromJson', () {
    test('reads a full profile', () {
      final profile = PassengerProfileModel.fromJson(const {
        'id': 'u-1',
        'fullName': 'Youcef Benali',
        'gender': 'FEMALE',
        'dateOfBirth': '1995-05-02',
        'email': 'y@example.com',
        'phone': '+213661234567',
        'status': 'ACTIVE',
        'activeRole': 'DRIVER',
        'hasDriverProfile': true,
        'profileCompleted': true,
        'hasPassengerProfile': true,
        'passenger': {'savedAddressCount': 2},
        'driver': {'kycStatus': 'REVOKED', 'requiresRekyc': true},
      });

      expect(profile.id, 'u-1');
      expect(profile.fullName, 'Youcef Benali');
      expect(profile.gender, Gender.female);
      expect(profile.dateOfBirth, DateTime(1995, 5, 2));
      expect(profile.email, 'y@example.com');
      expect(profile.phone, '+213661234567');
      expect(profile.activeRole, 'DRIVER');
      expect(profile.savedAddressCount, 2);
      expect(profile.driverKycStatus, KycStatus.revoked);
      expect(profile.driverRequiresRekyc, isTrue);
    });

    test('does not throw when optional fields are null or missing', () {
      final profile = PassengerProfileModel.fromJson(const {
        'id': null,
        'fullName': null,
        'dateOfBirth': null,
        'status': null,
      });

      expect(profile.id, '');
      expect(profile.fullName, '');
      expect(profile.gender, Gender.male);
      expect(profile.dateOfBirth, DateTime(2000));
      expect(profile.email, isNull);
      expect(profile.activeRole, 'PASSENGER');
      expect(profile.savedAddressCount, 0);
      expect(profile.driverKycStatus, KycStatus.none);
      expect(profile.driverRequiresRekyc, isFalse);
    });
  });

  group('KycSubmission.toFields', () {
    test('owns the KycSubmitRequest wire format', () {
      final submission = KycSubmission(
        firstName: ' Youcef ',
        lastName: 'Benali ',
        dateOfBirth: DateTime(1990, 1, 5),
        licenseNumber: ' 123456789',
        licenseExpiry: DateTime(2030, 12, 31),
        vehicleCategory: VehicleCategory.van,
        vehicleModel: 'Hiace ',
        vehicleColor: 'White',
        vehiclePlate: '12345-123-16',
        vehicleYear: 2018,
        insuranceExpiry: DateTime(2027, 3, 1),
        nationalIdPaths: const ['/a', '/b'],
        driverLicensePaths: const ['/c', '/d'],
        grayCardPath: '/e',
        insurancePath: '/f',
        carPicturePaths: const ['/g'],
      );

      expect(submission.toFields(), {
        'firstName': 'Youcef',
        'lastName': 'Benali',
        'dateOfBirth': '1990-01-05',
        'licenseNumber': '123456789',
        'licenseExpiry': '2030-12-31',
        'vehicleCategory': 'VAN',
        'vehicleModel': 'Hiace',
        'vehicleColor': 'White',
        'vehiclePlate': '12345 123 16',
        'vehicleYear': '2018',
        'insuranceExpiry': '2027-03-01',
      });
    });
  });

  group('KYC results', () {
    test('KycStatusResult reads the status and the latest submission', () {
      final result = KycStatusResult.fromJson(const {
        'kycStatus': 'REJECTED',
        'submission': {
          'id': 's-1',
          'status': 'REJECTED',
          'resubmissionNote': 'Photo floue',
          'submittedAt': '2026-10-01T09:30:00Z',
          'reviewedAt': '2026-10-02T14:00:00Z',
        },
      });

      expect(result.kycStatus, KycStatus.rejected);
      expect(result.submissionId, 's-1');
      expect(result.resubmissionNote, 'Photo floue');
      expect(result.submittedAt, DateTime.utc(2026, 10, 1, 9, 30));
      expect(result.reviewedAt, DateTime.utc(2026, 10, 2, 14));
    });

    test('KycStatusResult without a submission', () {
      final result = KycStatusResult.fromJson(const {'kycStatus': 'NONE'});

      expect(result, const KycStatusResult(kycStatus: KycStatus.none));
    });

    test('KycSubmitResult tolerates missing fields', () {
      expect(
        KycSubmitResult.fromJson(const {'submissionId': 's-1'}),
        const KycSubmitResult(submissionId: 's-1', status: ''),
      );
    });
  });
}
