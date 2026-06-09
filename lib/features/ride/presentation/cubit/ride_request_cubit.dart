import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/ride_models.dart';
import '../../data/ride_repository.dart';
import 'ride_request_state.dart';

final class RideRequestCubit extends Cubit<RideRequestState> {
  RideRequestCubit(this._repository) : super(const RideRequestState());

  final RideRepository _repository;

  void setServiceType(ServiceType value) =>
      emit(state.copyWith(serviceType: value));

  void setVehicleCategory(VehicleCategory value) =>
      emit(state.copyWith(vehicleCategory: value));

  void setFemaleOnly(bool value) =>
      emit(state.copyWith(femaleOnly: value));

  Future<void> submitRide(CreateRideRequest request) async {
    emit(state.copyWith(status: RideRequestStatus.loading, errorMessage: ''));
    try {
      await _repository.createRide(request);
      emit(state.copyWith(status: RideRequestStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: RideRequestStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
