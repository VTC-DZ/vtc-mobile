import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/api_exception.dart';
import '../../../data/models/passenger_ride_history_models.dart';
import '../../../data/passenger_ride_repository.dart';
import 'passenger_ride_detail_state.dart';

/// Loads the full detail of a single past ride, on top of the history entry
/// the passenger tapped.
class PassengerRideDetailCubit extends Cubit<PassengerRideDetailState> {
  PassengerRideDetailCubit(
    this._repository, {
    required PassengerRideHistoryItem summary,
  }) : super(PassengerRideDetailState(summary: summary));

  final PassengerRideRepository _repository;

  /// Also the retry action after a failure.
  Future<void> load() async {
    emit(state.copyWith(
      status: PassengerRideDetailStatus.loading,
      errorMessage: '',
    ));
    try {
      final detail =
          await _repository.getRideDetail(state.summary.rideRequestId);
      emit(state.copyWith(
        status: PassengerRideDetailStatus.loaded,
        detail: detail,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: e.statusCode == 404
            ? PassengerRideDetailStatus.notFound
            : PassengerRideDetailStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PassengerRideDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
