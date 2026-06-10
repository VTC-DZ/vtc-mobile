import 'package:equatable/equatable.dart';

import '../../../../../features/auth/data/models/passenger_profile_model.dart';
import '../../../../../features/ride/data/models/ride_models.dart';

enum PassengerHomeStatus { initial, loading, success, failure }

enum ActiveRideStatus { idle, loading, foundRequest, foundRide, none }

final class PassengerHomeState extends Equatable {
  const PassengerHomeState({
    this.status = PassengerHomeStatus.initial,
    this.profile,
    this.errorMessage = '',
    this.selectedIndex = 0,
    this.activeRideStatus = ActiveRideStatus.idle,
    this.activeRequest,
    this.activeRide,
  });

  final PassengerHomeStatus status;
  final PassengerProfileModel? profile;
  final String errorMessage;
  final int selectedIndex;
  final ActiveRideStatus activeRideStatus;
  final ActiveRequestSummary? activeRequest;
  final ActiveRideSummary? activeRide;

  PassengerHomeState copyWith({
    PassengerHomeStatus? status,
    PassengerProfileModel? profile,
    String? errorMessage,
    int? selectedIndex,
    ActiveRideStatus? activeRideStatus,
    ActiveRequestSummary? activeRequest,
    ActiveRideSummary? activeRide,
  }) {
    return PassengerHomeState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      activeRideStatus: activeRideStatus ?? this.activeRideStatus,
      activeRequest: activeRequest ?? this.activeRequest,
      activeRide: activeRide ?? this.activeRide,
    );
  }

  @override
  String toString() {
    return 'PassengerHomeState(status: $status, profile: $profile, errorMessage: $errorMessage, selectedIndex: $selectedIndex, activeRideStatus: $activeRideStatus)';
  }

  @override
  List<Object?> get props => [
        status,
        profile,
        errorMessage,
        selectedIndex,
        activeRideStatus,
        activeRequest,
        activeRide,
      ];
}
