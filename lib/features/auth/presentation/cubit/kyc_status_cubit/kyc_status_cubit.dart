import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khfif_drif/core/errors/api_exception.dart';

import '../../../data/repo/driver_repository.dart';
import 'kyc_status_state.dart';

final class KycStatusCubit extends Cubit<KycStatusState> {
  KycStatusCubit(this._driverRepository) : super(const KycStatusState()) {
    fetchKycStatus();
  }

  final DriverRepository _driverRepository;

  Future<void> fetchKycStatus() async {
    emit(state.copyWith(status: KycStatusViewStatus.loading));
    try {
      final result = await _driverRepository.getKycStatus();
      emit(state.copyWith(
        status: KycStatusViewStatus.success,
        kycResult: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: KycStatusViewStatus.failure,
        errorMessage: e is ApiException ? e.message : 'Failed to load KYC status.',
      ));
    }
  }
}
