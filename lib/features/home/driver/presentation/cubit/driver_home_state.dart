import 'package:equatable/equatable.dart';

import '../../../../../features/auth/data/models/driver_profile_model.dart';

enum DriverHomeStatus { initial, loading, success, failure }

enum DriverActiveRideCheckStatus { idle, loading, found, none }

final class DriverHomeState extends Equatable {
  const DriverHomeState({
    this.status = DriverHomeStatus.initial,
    this.profile,
    this.errorMessage = '',
    this.selectedIndex = 0,
    this.activeRideCheckStatus = DriverActiveRideCheckStatus.idle,
  });

  final DriverHomeStatus status;
  final DriverProfileModel? profile;
  final String errorMessage;
  final int selectedIndex;
  final DriverActiveRideCheckStatus activeRideCheckStatus;

  DriverHomeState copyWith({
    DriverHomeStatus? status,
    DriverProfileModel? profile,
    String? errorMessage,
    int? selectedIndex,
    DriverActiveRideCheckStatus? activeRideCheckStatus,
  }) {
    return DriverHomeState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      activeRideCheckStatus:
          activeRideCheckStatus ?? this.activeRideCheckStatus,
    );
  }

  @override
  List<Object?> get props =>
      [status, profile, errorMessage, selectedIndex, activeRideCheckStatus];
}
