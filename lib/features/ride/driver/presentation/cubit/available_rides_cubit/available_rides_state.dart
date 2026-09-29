import 'package:equatable/equatable.dart';

import '../../../data/models/driver_ride_models.dart';

enum AvailableRidesStatus {
  initial,
  loading,
  loaded,
  bidding,
  bidSuccess,
  offerAccepted,

  /// One of the driver's live bids ended without acceptance
  /// (`offer.rejected` / `offer.expired`) — see [AvailableRidesState.bidEndedReason].
  bidEnded,

  /// The bid was refused with `403 INSUFFICIENT_WALLET_BALANCE` — the driver
  /// needs a top-up, not an error toast.
  gatedByBalance,

  /// The bid hit a `409` — the view was stale (request closed, 3 bids live,
  /// …), so the list is refetched. A warning, not an error; the server's
  /// message is in [AvailableRidesState.errorMessage].
  bidConflict,
  failure,
}

/// `bidEndedReason` for `offer.expired` — the other values are the server's
/// `offer.rejected.reason` enum (swagger/epic-03-ride.md §5).
const String bidExpiredReason = 'EXPIRED';

final class AvailableRidesState extends Equatable {
  const AvailableRidesState({
    this.status = AvailableRidesStatus.initial,
    this.rides = const [],
    this.pendingBids = const {},
    this.bidEndedReason = '',
    this.errorMessage = '',
  });

  final AvailableRidesStatus status;
  final List<AvailableRequestCard> rides;

  /// The driver's live bids, keyed by `rideRequestId`. In-memory only: the
  /// available-rides REST list carries no "my bid" info.
  final Map<String, BidResponse> pendingBids;

  /// Why the last bid ended; meaningful only while [status] is `bidEnded`.
  final String bidEndedReason;
  final String errorMessage;

  AvailableRidesState copyWith({
    AvailableRidesStatus? status,
    List<AvailableRequestCard>? rides,
    Map<String, BidResponse>? pendingBids,
    String? bidEndedReason,
    String? errorMessage,
  }) =>
      AvailableRidesState(
        status: status ?? this.status,
        rides: rides ?? this.rides,
        pendingBids: pendingBids ?? this.pendingBids,
        bidEndedReason: bidEndedReason ?? this.bidEndedReason,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, rides, pendingBids, bidEndedReason, errorMessage];
}
