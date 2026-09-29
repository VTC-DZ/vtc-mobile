import 'package:equatable/equatable.dart';

import '../../../data/models/passenger_ride_models.dart';

/// `expired` = the request ended server-side without an accepted offer (auto
/// cancel on `NO_DRIVERS` / `TIMEOUT`), as opposed to the passenger's cancel.
enum RideRequestPhase { requested, negotiating, accepted, cancelled, expired }

enum AcceptStatus { initial, loading, success, failure }

enum CancelStatus { initial, loading, success, failure }

enum RefuseStatus { initial, loading, success, failure }

final class WaitingOffersState extends Equatable {
  const WaitingOffersState({
    this.acceptStatus = AcceptStatus.initial,
    this.cancelStatus = CancelStatus.initial,
    this.refuseStatus = RefuseStatus.initial,
    this.offers = const [],
    this.rideRequestPhase = RideRequestPhase.requested,
    this.errorMessage = '',
    this.acceptingOfferId = '',
    this.endReason = '',
  });

  final AcceptStatus acceptStatus;
  final CancelStatus cancelStatus;
  final RefuseStatus refuseStatus;
  final List<OfferEntry> offers;
  final RideRequestPhase rideRequestPhase;
  final String errorMessage;

  /// The offer being (or last) accepted, so only its card shows a spinner.
  final String acceptingOfferId;

  /// Why the request expired (`NO_DRIVERS` / `TIMEOUT`); empty when unknown.
  final String endReason;

  WaitingOffersState copyWith({
    AcceptStatus? acceptStatus,
    CancelStatus? cancelStatus,
    RefuseStatus? refuseStatus,
    List<OfferEntry>? offers,
    RideRequestPhase? rideRequestPhase,
    String? errorMessage,
    String? acceptingOfferId,
    String? endReason,
  }) =>
      WaitingOffersState(
        acceptStatus: acceptStatus ?? this.acceptStatus,
        cancelStatus: cancelStatus ?? this.cancelStatus,
        refuseStatus: refuseStatus ?? this.refuseStatus,
        offers: offers ?? this.offers,
        rideRequestPhase: rideRequestPhase ?? this.rideRequestPhase,
        errorMessage: errorMessage ?? this.errorMessage,
        acceptingOfferId: acceptingOfferId ?? this.acceptingOfferId,
        endReason: endReason ?? this.endReason,
      );

  @override
  List<Object?> get props => [
        acceptStatus,
        cancelStatus,
        refuseStatus,
        offers,
        rideRequestPhase,
        errorMessage,
        acceptingOfferId,
        endReason,
      ];
}
