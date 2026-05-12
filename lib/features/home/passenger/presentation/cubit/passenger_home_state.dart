import 'package:equatable/equatable.dart';

import '../../../../../features/auth/data/models/passenger_profile_model.dart';

enum PassengerHomeStatus { initial, loading, success, failure }

final class PassengerHomeState extends Equatable {
  const PassengerHomeState({
    this.status = PassengerHomeStatus.initial,
    this.profile,
    this.errorMessage = '',
    this.selectedIndex = 0,
  });

  final PassengerHomeStatus status;
  final PassengerProfileModel? profile;
  final String errorMessage;
  final int selectedIndex;

  PassengerHomeState copyWith({
    PassengerHomeStatus? status,
    PassengerProfileModel? profile,
    String? errorMessage,
    int? selectedIndex,
  }) {
    return PassengerHomeState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  @override
  String toString() {
    return 'PassengerHomeState(status: $status, profile: $profile, errorMessage: $errorMessage, selectedIndex: $selectedIndex)';
  }

  @override
  List<Object?> get props => [status, profile, errorMessage, selectedIndex];
}
