import 'package:equatable/equatable.dart';

import '../../../data/models/ride_models.dart';

enum WaitingOffersStatus { polling, accepting, accepted, cancelling, cancelled, error }

final class WaitingOffersState extends Equatable {
  const WaitingOffersState({
    this.status = WaitingOffersStatus.polling,
    this.offers = const [],
    this.rideRequestPhase = 'REQUESTED',
    this.errorMessage = '',
  });

  final WaitingOffersStatus status;
  final List<OfferEntry> offers;
  final String rideRequestPhase;
  final String errorMessage;

  WaitingOffersState copyWith({
    WaitingOffersStatus? status,
    List<OfferEntry>? offers,
    String? rideRequestPhase,
    String? errorMessage,
  }) =>
      WaitingOffersState(
        status: status ?? this.status,
        offers: offers ?? this.offers,
        rideRequestPhase: rideRequestPhase ?? this.rideRequestPhase,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, offers, rideRequestPhase, errorMessage];
}
