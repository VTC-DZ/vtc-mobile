import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/models/token_payload.dart';
import '../../../../../../core/network/ride_socket_service.dart';
import '../../../data/models/passenger_ride_models.dart';
import '../../../data/passenger_ride_repository.dart';
import '../../../../../ride/driver/data/models/ride_socket_event.dart';
import 'waiting_offers_state.dart';

final class WaitingOffersCubit extends Cubit<WaitingOffersState> {
  WaitingOffersCubit(this._repository, this._rideRequestId)
      : super(const WaitingOffersState());

  final PassengerRideRepository _repository;
  final String _rideRequestId;
  StreamSubscription<String>? _wsSub;
  StreamSubscription<RideSocketStatus>? _statusSub;

  void startPolling() {
    // On cold start (app reopened on this screen) the socket is not connected,
    // so no offer.created frames arrive. Connect here — idempotent, so it is a
    // no-op when the fresh-request flow already opened the socket.
    RideSocketService.connect(ActiveRole.passenger);
    _poll();
    _wsSub = RideSocketService.frameStream.listen((frame) {
      final event = RideSocketEvent.tryParse(frame);
      switch (event) {
        case OfferCreated(:final rideRequestId, :final offerId, :final fare)
            when rideRequestId == _rideRequestId:
          if (kDebugMode) {
            debugPrint('[Passenger] offer.created → '
                'offerId=$offerId fare=$fare DZD');
          }
          _poll();
        // Covers an accept made from another device, or our own accept whose
        // REST response was lost after the server committed it.
        case OfferAccepted(:final rideRequestId)
            when rideRequestId == _rideRequestId:
          _markAccepted();
        // The offer is gone server-side (timed out, or the driver went
        // offline / took another ride) — drop the card before the passenger
        // taps Accept on it and gets a 409.
        case OfferRejected(:final rideRequestId, :final offerId)
            when rideRequestId == _rideRequestId:
          removeOffer(offerId);
        case OfferExpired(:final rideRequestId, :final offerId)
            when rideRequestId == _rideRequestId:
          removeOffer(offerId);
        // Reserved (not emitted in v1): the counter supersedes the previous
        // offer — drop that card, then let REST decide what is live.
        case OfferCountered(:final rideRequestId, :final previousOfferId)
            when rideRequestId == _rideRequestId:
          if (previousOfferId != null) removeOffer(previousOfferId);
          _poll();
        default:
          break;
      }
    });
    // REST is truth on (re)connect: reconcile offers once each time the socket
    // comes up, catching any bid that landed while it was down.
    _statusSub = RideSocketService.statusStream.listen((status) {
      if (status == RideSocketStatus.connected) _poll();
    });
  }

  Future<void> _poll() async {
    if (state.acceptStatus == AcceptStatus.success ||
        state.cancelStatus == CancelStatus.loading ||
        state.cancelStatus == CancelStatus.success) {
      return;
    }
    try {
      final result = await _repository.listOffers(_rideRequestId);
      if (isClosed) return;
      // An accept we missed (e.g. while the socket was down) — move on.
      if (result.offers.any((o) => o.status == 'ACCEPTED')) {
        _markAccepted();
        return;
      }
      final active = result.offers.where((o) => o.status == 'ACTIVE').toList();
      final phase = active.isEmpty
          ? RideRequestPhase.requested
          : RideRequestPhase.negotiating;
      emit(state.copyWith(offers: active, rideRequestPhase: phase));
    } catch (_) {
      // silently skip failed polls; show last known offers
    }
  }

  /// The request now has a ride, however we learnt it: our REST accept, an
  /// `offer.accepted` frame, or a poll showing an ACCEPTED offer. Runs once;
  /// later signals are no-ops.
  void _markAccepted() {
    if (isClosed || state.acceptStatus == AcceptStatus.success) return;
    _wsSub?.cancel();
    _statusSub?.cancel();
    emit(state.copyWith(
      acceptStatus: AcceptStatus.success,
      rideRequestPhase: RideRequestPhase.accepted,
    ));
  }

  void removeOffer(String offerId) {
    final remaining = state.offers.where((o) => o.offerId != offerId).toList();
    final phase = remaining.isEmpty
        ? RideRequestPhase.requested
        : RideRequestPhase.negotiating;
    emit(state.copyWith(offers: remaining, rideRequestPhase: phase));
  }

  Future<void> acceptOffer(String offerId) async {
    emit(state.copyWith(
      acceptStatus: AcceptStatus.loading,
      acceptingOfferId: offerId,
    ));
    try {
      await _repository.acceptOffer(_rideRequestId, offerId);
      _markAccepted();
    } catch (e) {
      // The offer.accepted frame may have already won and navigated away.
      if (isClosed || state.acceptStatus == AcceptStatus.success) return;
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
      final phase = remaining.isEmpty
          ? RideRequestPhase.requested
          : RideRequestPhase.negotiating;
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
      _wsSub?.cancel();
      _statusSub?.cancel();
      emit(state.copyWith(
        cancelStatus: CancelStatus.success,
        rideRequestPhase: RideRequestPhase.cancelled,
      ));
    } catch (e) {
      // An accept landed mid-cancel and the screen already moved on.
      if (isClosed) return;
      emit(state.copyWith(
        cancelStatus: CancelStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
