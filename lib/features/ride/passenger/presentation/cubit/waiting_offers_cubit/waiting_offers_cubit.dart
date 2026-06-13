import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/passenger_ride_models.dart';
import '../../../data/passenger_ride_repository.dart';
import 'waiting_offers_state.dart';

final class WaitingOffersCubit extends Cubit<WaitingOffersState> {
  WaitingOffersCubit(this._repository, this._rideRequestId)
      : super(const WaitingOffersState());

  final PassengerRideRepository _repository;
  final String _rideRequestId;
  Timer? _timer;

  void startPolling() {
    _poll();
    // _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    if (state.acceptStatus == AcceptStatus.success ||
        state.cancelStatus == CancelStatus.loading ||
        state.cancelStatus == CancelStatus.success) {
      return;
    }
    try {
      final result = await _repository.listOffers(_rideRequestId);
      final active = result.offers.where((o) => o.status == 'ACTIVE').toList();
      final phase = active.isEmpty ? RideRequestPhase.requested : RideRequestPhase.negotiating;
      emit(state.copyWith(offers: active, rideRequestPhase: phase));
    } catch (_) {
      // silently skip failed polls; show last known offers
    }
  }

  Future<void> acceptOffer(String offerId) async {
    emit(state.copyWith(acceptStatus: AcceptStatus.loading));
    try {
      await _repository.acceptOffer(_rideRequestId, offerId);
      _timer?.cancel();
      emit(state.copyWith(
        acceptStatus: AcceptStatus.success,
        rideRequestPhase: RideRequestPhase.accepted,
      ));
    } catch (e) {
      emit(state.copyWith(
        acceptStatus: AcceptStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> refuseOffer(String offerId) async {
    emit(state.copyWith(refuseStatus: RefuseStatus.loading));
    try {
      await _repository.refuseOffer(_rideRequestId, offerId);
      final remaining =
          state.offers.where((o) => o.offerId != offerId).toList();
      final phase = remaining.isEmpty ? RideRequestPhase.requested : RideRequestPhase.negotiating;
      emit(state.copyWith(
        refuseStatus: RefuseStatus.success,
        offers: remaining,
        rideRequestPhase: phase,
      ));
    } catch (e) {
      emit(state.copyWith(
        refuseStatus: RefuseStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> cancelRide(CancelReason reason, {String? note}) async {
    emit(state.copyWith(cancelStatus: CancelStatus.loading));
    try {
      await _repository.cancelRide(
        _rideRequestId,
        CancelRideRequest(reason: reason.apiValue, note: note),
      );
      _timer?.cancel();
      emit(state.copyWith(
        cancelStatus: CancelStatus.success,
        rideRequestPhase: RideRequestPhase.cancelled,
      ));
    } catch (e) {
      emit(state.copyWith(
        cancelStatus: CancelStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
