import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/ride_repository.dart';
import 'waiting_offers_state.dart';

final class WaitingOffersCubit extends Cubit<WaitingOffersState> {
  WaitingOffersCubit(this._repository, this._rideRequestId)
      : super(const WaitingOffersState());

  final RideRepository _repository;
  final String _rideRequestId;
  Timer? _timer;

  void startPolling() {
    _poll();
    // _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    if (state.status == WaitingOffersStatus.accepted) return;
    try {
      final result = await _repository.listOffers(_rideRequestId);
      final active = result.offers.where((o) => o.status == 'ACTIVE').toList();
      final phase = active.isEmpty ? 'REQUESTED' : 'NEGOTIATING';
      emit(state.copyWith(
        status: WaitingOffersStatus.polling,
        offers: active,
        rideRequestPhase: phase,
      ));
    } catch (_) {
      // silently skip failed polls; show last known offers
    }
  }

  Future<void> acceptOffer(String offerId) async {
    emit(state.copyWith(status: WaitingOffersStatus.accepting));
    try {
      await _repository.acceptOffer(_rideRequestId, offerId);
      _timer?.cancel();
      emit(state.copyWith(
        status: WaitingOffersStatus.accepted,
        rideRequestPhase: 'ACCEPTED',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WaitingOffersStatus.polling,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> refuseOffer(String offerId) async {
    try {
      await _repository.refuseOffer(_rideRequestId, offerId);
      final remaining =
          state.offers.where((o) => o.offerId != offerId).toList();
      final phase = remaining.isEmpty ? 'REQUESTED' : 'NEGOTIATING';
      emit(state.copyWith(offers: remaining, rideRequestPhase: phase));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
