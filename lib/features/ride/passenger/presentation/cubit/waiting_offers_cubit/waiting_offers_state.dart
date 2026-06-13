import 'package:equatable/equatable.dart';

import '../../../data/models/passenger_ride_models.dart';

enum RideRequestPhase { requested, negotiating, accepted, cancelled }

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
  });

  final AcceptStatus acceptStatus;
  final CancelStatus cancelStatus;
  final RefuseStatus refuseStatus;
  final List<OfferEntry> offers;
  final RideRequestPhase rideRequestPhase;
  final String errorMessage;

  WaitingOffersState copyWith({
    AcceptStatus? acceptStatus,
    CancelStatus? cancelStatus,
    RefuseStatus? refuseStatus,
    List<OfferEntry>? offers,
    RideRequestPhase? rideRequestPhase,
    String? errorMessage,
  }) =>
      WaitingOffersState(
        acceptStatus: acceptStatus ?? this.acceptStatus,
        cancelStatus: cancelStatus ?? this.cancelStatus,
        refuseStatus: refuseStatus ?? this.refuseStatus,
        offers: offers ?? this.offers,
        rideRequestPhase: rideRequestPhase ?? this.rideRequestPhase,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        acceptStatus,
        cancelStatus,
        refuseStatus,
        offers,
        rideRequestPhase,
        errorMessage,
      ];
}
