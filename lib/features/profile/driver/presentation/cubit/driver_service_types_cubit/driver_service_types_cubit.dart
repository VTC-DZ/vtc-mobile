import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../ride/shared/models/shared_ride_models.dart';
import '../../../data/driver_service_types_repository.dart';
import 'driver_service_types_state.dart';

class DriverServiceTypesCubit extends Cubit<DriverServiceTypesState> {
  DriverServiceTypesCubit(this._repo) : super(const DriverServiceTypesState());

  final DriverServiceTypesRepository _repo;

  void seed(Set<ServiceType> types) {
    emit(state.copyWith(activeTypes: types));
  }

  Future<void> toggle(ServiceType type, bool enabled) async {
    if (state.status == DriverServiceTypesStatus.loading) return;
    emit(state.copyWith(
      status: DriverServiceTypesStatus.loading,
      pendingType: type,
      errorMessage: '',
    ));
    try {
      final updated = await _repo.setServiceType(type, enabled);
      emit(state.copyWith(
        status: DriverServiceTypesStatus.success,
        activeTypes: updated,
        clearPending: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DriverServiceTypesStatus.failed,
        errorMessage: e is String ? e : 'Failed to update service types.',
        clearPending: true,
      ));
    }
  }
}
