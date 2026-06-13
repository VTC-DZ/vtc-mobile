import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/driver_availability_repository.dart';
import 'driver_availability_state.dart';

class DriverAvailabilityCubit extends Cubit<DriverAvailabilityState> {
  DriverAvailabilityCubit(this._repo) : super(const DriverAvailabilityState());

  final DriverAvailabilityRepository _repo;

  Future<void> toggle() async {
    if (state.status == DriverAvailabilityStatus.loading) return;
    emit(state.copyWith(status: DriverAvailabilityStatus.loading));
    try {
      final isOnline =
          state.isOnline ? await _repo.goOffline() : await _repo.goOnline();
      emit(state.copyWith(
        status: DriverAvailabilityStatus.success,
        isOnline: isOnline,
      ));
    } catch (_) {
      emit(state.copyWith(status: DriverAvailabilityStatus.failed));
    }
  }
}
