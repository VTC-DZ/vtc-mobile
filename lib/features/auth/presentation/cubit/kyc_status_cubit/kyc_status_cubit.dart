import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/api_exception.dart';
import '../../../../profile/shared/data/models/kyc_status.dart';
import '../../../../profile/shared/data/models/passenger_profile_model.dart';
import '../../../../profile/shared/data/profile_repository.dart';
import '../../../data/kyc_repository.dart';
import 'kyc_status_state.dart';
import '../../../../../core/constants/app_strings.dart';

final class KycStatusCubit extends Cubit<KycStatusState> {
  KycStatusCubit(this._kycRepository, this._profileRepository)
      : super(const KycStatusState()) {
    fetchKycStatus();
  }

  final KycRepository _kycRepository;
  final ProfileRepository _profileRepository;

  Future<void> fetchKycStatus() async {
    emit(state.copyWith(status: KycStatusViewStatus.loading));
    try {
      final result = await _kycRepository.getKycStatus();
      final profile = await _profileFor(result.kycStatus);
      emit(KycStatusState(
        status: KycStatusViewStatus.success,
        kycResult: result,
        profile: profile,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: KycStatusViewStatus.failure,
        errorMessage: ApiException.messageOf(e,
            fallback: AppStrings.kycStatusLoadFailed),
      ));
    }
  }

  /// The account behind a rejected or revoked application. It pre-fills the
  /// re-submission, and for a revoked driver it says whether one is allowed
  /// (`driver.requiresRekyc`); the KYC status carries neither.
  Future<PassengerProfileModel?> _profileFor(KycStatus status) async {
    switch (status) {
      case KycStatus.revoked:
        // Without it the screen can't tell what to offer, so a failure fails
        // the whole load (and the screen offers Retry).
        return _profileRepository.getProfile();
      case KycStatus.rejected:
        // Only for the pre-fill: a failure must not hide the rejection.
        try {
          return await _profileRepository.getProfile();
        } catch (_) {
          return null;
        }
      case KycStatus.none:
      case KycStatus.pending:
      case KycStatus.approved:
        return null;
    }
  }
}
