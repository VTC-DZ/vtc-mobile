import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/driver_ride_repository.dart';
import 'available_rides_state.dart';

final class AvailableRidesCubit extends Cubit<AvailableRidesState> {
  AvailableRidesCubit(this._repository) : super(const AvailableRidesState());

  final DriverRideRepository _repository;

  Future<void> loadAvailableRides() async {
    emit(state.copyWith(status: AvailableRidesStatus.loading, errorMessage: ''));
    try {
      final response = await _repository.listAvailableRides();
      emit(state.copyWith(
        status: AvailableRidesStatus.loaded,
        rides: response.requests,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AvailableRidesStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> submitBid(String rideRequestId, int fare) async {
    emit(state.copyWith(status: AvailableRidesStatus.bidding, errorMessage: ''));
    try {
      await _repository.submitBid(rideRequestId, fare);
      emit(state.copyWith(status: AvailableRidesStatus.bidSuccess));
    } catch (e) {
      emit(state.copyWith(
        status: AvailableRidesStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
