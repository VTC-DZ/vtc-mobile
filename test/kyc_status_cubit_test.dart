import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/errors/api_exception.dart';
import 'package:rapidoo/core/models/gender.dart';
import 'package:rapidoo/features/auth/data/kyc_repository.dart';
import 'package:rapidoo/features/auth/data/models/kyc_status_result.dart';
import 'package:rapidoo/features/auth/presentation/cubit/kyc_status_cubit/kyc_status_cubit.dart';
import 'package:rapidoo/features/auth/presentation/cubit/kyc_status_cubit/kyc_status_state.dart';
import 'package:rapidoo/features/profile/shared/data/models/kyc_status.dart';
import 'package:rapidoo/features/profile/shared/data/models/passenger_profile_model.dart';
import 'package:rapidoo/features/profile/shared/data/profile_repository.dart';

/// Answers `getKycStatus` with [result], or throws [error] when set.
class _FakeKycRepository extends KycRepository {
  _FakeKycRepository(this.result);

  KycStatusResult result;
  Object? error;
  int calls = 0;

  @override
  Future<KycStatusResult> getKycStatus() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }
}

/// Answers `getProfile` with a driver account, or throws [error] when set.
class _FakeProfileRepository extends ProfileRepository {
  bool requiresRekyc = false;
  Object? error;
  int calls = 0;

  @override
  Future<PassengerProfileModel> getProfile() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return PassengerProfileModel(
      id: 'u-1',
      fullName: 'Youcef Benali',
      gender: Gender.male,
      dateOfBirth: DateTime(1990, 1, 1),
      status: 'ACTIVE',
      hasDriverProfile: true,
      profileCompleted: true,
      activeRole: 'PASSENGER',
      hasPassengerProfile: true,
      savedAddressCount: 0,
      driverKycStatus: KycStatus.revoked,
      driverRequiresRekyc: requiresRekyc,
    );
  }
}

Future<KycStatusState> _settled(KycStatusCubit cubit) => cubit.stream
    .firstWhere((s) =>
        s.status == KycStatusViewStatus.success ||
        s.status == KycStatusViewStatus.failure);

void main() {
  late _FakeProfileRepository profiles;

  setUp(() => profiles = _FakeProfileRepository());

  KycStatusCubit cubitFor(KycStatusResult result) {
    final cubit = KycStatusCubit(_FakeKycRepository(result), profiles);
    addTearDown(cubit.close);
    return cubit;
  }

  test('loads the status as soon as it is created', () async {
    final repository = _FakeKycRepository(
      const KycStatusResult(kycStatus: KycStatus.pending),
    );
    final cubit = KycStatusCubit(repository, profiles);
    addTearDown(cubit.close);

    final state = await _settled(cubit);

    expect(repository.calls, 1);
    expect(state.status, KycStatusViewStatus.success);
    expect(state.isPending, isTrue);
    expect(profiles.calls, 0, reason: 'only a closed application needs it');
  });

  group('rejected', () {
    test('loads the account to pre-fill the re-submission', () async {
      final state = await _settled(cubitFor(const KycStatusResult(
        kycStatus: KycStatus.rejected,
        resubmissionNote: 'Photo floue',
      )));

      expect(state.isRejected, isTrue);
      expect(state.canResubmit, isTrue);
      expect(state.profile?.fullName, 'Youcef Benali');
      expect(state.kycResult?.resubmissionNote, 'Photo floue');
    });

    test('still shows when the account cannot load', () async {
      profiles.error = const ApiException(message: 'Service indisponible');

      final state = await _settled(cubitFor(
        const KycStatusResult(kycStatus: KycStatus.rejected),
      ));

      expect(state.status, KycStatusViewStatus.success);
      expect(state.profile, isNull);
      expect(state.canResubmit, isTrue);
    });
  });

  group('revoked', () {
    test('may re-submit when the server asks for new documents', () async {
      profiles.requiresRekyc = true;

      final state = await _settled(cubitFor(
        const KycStatusResult(kycStatus: KycStatus.revoked),
      ));

      expect(state.isRevoked, isTrue);
      expect(state.isPending, isFalse);
      expect(state.canResubmit, isTrue);
    });

    test('may not re-submit otherwise', () async {
      final state = await _settled(cubitFor(
        const KycStatusResult(kycStatus: KycStatus.revoked),
      ));

      expect(state.isRevoked, isTrue);
      expect(state.canResubmit, isFalse);
    });

    test('fails, to offer Retry, when the account cannot load', () async {
      profiles.error = const ApiException(message: 'Service indisponible');

      final state = await _settled(cubitFor(
        const KycStatusResult(kycStatus: KycStatus.revoked),
      ));

      expect(state.status, KycStatusViewStatus.failure);
      expect(state.errorMessage, 'Service indisponible');
    });
  });

  test('shows the server message on failure, then recovers on retry',
      () async {
    final repository = _FakeKycRepository(
      const KycStatusResult(kycStatus: KycStatus.approved),
    )..error = const ApiException(message: 'Service indisponible');
    final cubit = KycStatusCubit(repository, profiles);
    addTearDown(cubit.close);

    final failed = await _settled(cubit);
    expect(failed.status, KycStatusViewStatus.failure);
    expect(failed.errorMessage, 'Service indisponible');

    repository.error = null;
    await cubit.fetchKycStatus();

    expect(cubit.state.status, KycStatusViewStatus.success);
    expect(cubit.state.isApproved, isTrue);
    expect(cubit.state.errorMessage, isEmpty);
  });
}
