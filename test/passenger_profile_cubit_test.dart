import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/errors/api_exception.dart';
import 'package:rapidoo/core/models/gender.dart';
import 'package:rapidoo/features/profile/shared/data/models/kyc_status.dart';
import 'package:rapidoo/features/profile/shared/data/models/passenger_profile_model.dart';
import 'package:rapidoo/features/profile/shared/data/profile_repository.dart';
import 'package:rapidoo/features/auth/presentation/cubit/passenger_profile_cubit/passenger_profile_cubit.dart';
import 'package:rapidoo/features/auth/presentation/cubit/passenger_profile_cubit/passenger_profile_state.dart';

/// Records what `saveProfile` was called with, and can fail on demand.
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
    return PassengerProfileModel(
      id: 'u-1',
      fullName: fullName,
      gender: gender,
      dateOfBirth: dateOfBirth,
      status: 'ACTIVE',
      hasDriverProfile: false,
      profileCompleted: true,
      activeRole: 'PASSENGER',
      hasPassengerProfile: true,
      savedAddressCount: 0,
      driverKycStatus: KycStatus.none,
    );
  }
}

void main() {
  late _FakeProfileRepository repository;
  late PassengerProfileCubit cubit;

  setUp(() {
    repository = _FakeProfileRepository();
    cubit = PassengerProfileCubit(repository);
  });
  tearDown(() => cubit.close());

  void pickGenderAndBirthDate() {
    cubit
      ..genderChanged(Gender.female)
      ..dateOfBirthChanged(DateTime(1995, 5, 2));
  }

  test('cannot submit before a name is typed', () async {
    pickGenderAndBirthDate();

    expect(cubit.state.canSubmit, isFalse);

    await cubit.submit();
    expect(repository.saved, isEmpty);
  });

  test('cannot submit with an invalid name', () {
    pickGenderAndBirthDate();
    cubit.nameChanged('A');

    expect(cubit.state.nameError, isNotEmpty);
    expect(cubit.state.canSubmit, isFalse);
  });

  test('submits the trimmed name with gender and birth date', () async {
    pickGenderAndBirthDate();
    cubit.nameChanged('  Amina Benali ');
    expect(cubit.state.canSubmit, isTrue);

    await cubit.submit();

    expect(repository.saved.single.fullName, 'Amina Benali');
    expect(repository.saved.single.gender, Gender.female);
    expect(repository.saved.single.dateOfBirth, DateTime(1995, 5, 2));
    expect(cubit.state.status, ProfileStatus.success);
  });

  test('shows the server message when saving fails', () async {
    repository.error = const ApiException(message: 'Nom invalide');
    pickGenderAndBirthDate();
    cubit.nameChanged('Amina Benali');

    await cubit.submit();

    expect(cubit.state.status, ProfileStatus.failure);
    expect(cubit.state.errorMessage, 'Nom invalide');
  });
}
