import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/constants/wallet_api_constants.dart';
import '../../../../../../core/errors/api_exception.dart';
import '../../../../../../core/network/ride_socket_service.dart';
import '../../../data/driver_ride_repository.dart';
import '../../../data/models/driver_ride_models.dart';
import '../../../data/models/ride_socket_event.dart';
import 'available_rides_state.dart';

final class AvailableRidesCubit extends Cubit<AvailableRidesState> {
  AvailableRidesCubit(this._repository) : super(const AvailableRidesState()) {
    _frameSub = RideSocketService.frameStream.listen(_onFrame);
    _statusSub = RideSocketService.statusStream.listen(_onStatus);
    // The socket may already be live when this cubit mounts (e.g. the driver was
    // online before navigating here) — seed straight away so we don't wait for
    // the next connect event.
    if (RideSocketService.status == RideSocketStatus.connected) {
      loadAvailableRides();
    }
  }

  final DriverRideRepository _repository;
  late final StreamSubscription<String> _frameSub;
  late final StreamSubscription<RideSocketStatus> _statusSub;

  Future<void> loadAvailableRides() async {
    emit(
        state.copyWith(status: AvailableRidesStatus.loading, errorMessage: ''));
    try {
      final response = await _repository.listAvailableRides();
      // Keep bids only for requests that are still open and bids that haven't
      // timed out — the rest ended while the socket was down, so their
      // offer.rejected / offer.expired frames were missed.
      final openIds = {for (final r in response.requests) r.rideRequestId};
      final now = DateTime.now();
      final pendingBids = Map.of(state.pendingBids)
        ..removeWhere((id, bid) =>
            !openIds.contains(id) ||
            (DateTime.tryParse(bid.expiresAt)?.isBefore(now) ?? false));
      emit(state.copyWith(
        status: AvailableRidesStatus.loaded,
        rides: response.requests,
        pendingBids: pendingBids,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AvailableRidesStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> submitBid(String rideRequestId, int fare) async {
    emit(
        state.copyWith(status: AvailableRidesStatus.bidding, errorMessage: ''));
    try {
      final bid = await _repository.submitBid(rideRequestId, fare);
      emit(state.copyWith(
        status: AvailableRidesStatus.bidSuccess,
        pendingBids: {...state.pendingBids, rideRequestId: bid},
      ));
    } catch (e) {
      // The wallet gate blocks bidding just as it blocks going online. It has a
      // concrete fix, so it gets its own status: DriverHomeShell renders it as
      // a "Top up" prompt instead of a generic failure snackbar.
      final gated =
          e is ApiException && e.code == WalletErrorCodes.insufficientBalance;
      emit(state.copyWith(
        status: gated
            ? AvailableRidesStatus.gatedByBalance
            : AvailableRidesStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  // REST is truth, WS is hints: reconcile against REST on every (re)connect, then
  // apply the live broadcast deltas on top.
  void _onStatus(RideSocketStatus status) {
    if (status == RideSocketStatus.connected) loadAvailableRides();
  }

  void _onFrame(String frame) {
    final event = RideSocketEvent.tryParse(frame);
    switch (event) {
      case RideBroadcast(:final request):
        _upsertRide(request);
      case RideBroadcastCancelled(:final rideRequestId):
        _removeRide(rideRequestId);
      case OfferAccepted(:final rideRequestId):
        // The driver's bid was accepted — drop this card so it can't resurface
        // (e.g. after the ride is later cancelled and the driver returns home).
        // The cubit is shell-scoped, so the list otherwise persists in memory.
        final rides =
            state.rides.where((r) => r.rideRequestId != rideRequestId).toList();
        emit(state.copyWith(
          status: AvailableRidesStatus.offerAccepted,
          rides: rides,
          pendingBids: _withoutBid(rideRequestId),
        ));
      case OfferRejected(:final rideRequestId, :final reason):
        _endBid(rideRequestId, reason);
      case OfferExpired(:final rideRequestId):
        _endBid(rideRequestId, bidExpiredReason);
      default:
        break;
    }
  }

  // Dedupe by rideRequestId: the re-broadcast sweeper re-emits the same request
  // as the cohort grows, so replace an existing card rather than appending.
  void _upsertRide(AvailableRequestCard request) {
    final rides = List<AvailableRequestCard>.from(state.rides);
    final index =
        rides.indexWhere((r) => r.rideRequestId == request.rideRequestId);
    if (index >= 0) {
      rides[index] = request;
    } else {
      rides.add(request);
    }
    emit(state.copyWith(status: AvailableRidesStatus.loaded, rides: rides));
  }

  void ignoreRide(String rideRequestId) => _removeRide(rideRequestId);

  void _removeRide(String rideRequestId) {
    final rides =
        state.rides.where((r) => r.rideRequestId != rideRequestId).toList();
    emit(state.copyWith(
      status: AvailableRidesStatus.loaded,
      rides: rides,
      pendingBids: _withoutBid(rideRequestId),
    ));
  }

  // The driver's bid ended without acceptance (driver-flow.md Step 6): the
  // card goes either way. Only tell the driver when we actually held that bid,
  // and not for DRIVER_OFFLINE — going offline was their own action.
  void _endBid(String rideRequestId, String reason) {
    final hadBid = state.pendingBids.containsKey(rideRequestId);
    if (!hadBid || reason == 'DRIVER_OFFLINE') {
      _removeRide(rideRequestId);
      return;
    }
    emit(state.copyWith(
      status: AvailableRidesStatus.bidEnded,
      bidEndedReason: reason,
      rides:
          state.rides.where((r) => r.rideRequestId != rideRequestId).toList(),
      pendingBids: _withoutBid(rideRequestId),
    ));
  }

  Map<String, BidResponse> _withoutBid(String rideRequestId) =>
      Map.of(state.pendingBids)..remove(rideRequestId);

  @override
  Future<void> close() {
    _frameSub.cancel();
    _statusSub.cancel();
    return super.close();
  }
}
