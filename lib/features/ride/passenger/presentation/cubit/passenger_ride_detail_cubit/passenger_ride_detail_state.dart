import 'package:equatable/equatable.dart';

import '../../../data/models/passenger_ride_detail_models.dart';
import '../../../data/models/passenger_ride_history_models.dart';

enum PassengerRideDetailStatus { initial, loading, loaded, failure, notFound }

final class PassengerRideDetailState extends Equatable {
  const PassengerRideDetailState({
    required this.summary,
    this.status = PassengerRideDetailStatus.initial,
    this.detail,
    this.errorMessage = '',
  });

  /// The tapped history entry — rendered immediately, and the only source of
  /// the addresses, service type and cancellation reason (the detail endpoint
  /// doesn't return them).
  final PassengerRideHistoryItem summary;

  final PassengerRideDetailStatus status;
  final PassengerRideDetail? detail;
  final String errorMessage;

  PassengerRideDetailState copyWith({
    PassengerRideDetailStatus? status,
    PassengerRideDetail? detail,
    String? errorMessage,
  }) {
    return PassengerRideDetailState(
      summary: summary,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [summary, status, detail, errorMessage];
}
