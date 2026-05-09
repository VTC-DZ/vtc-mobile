import 'package:equatable/equatable.dart';

import '../../../../../features/auth/data/models/passenger_profile_model.dart';

enum PassengerHomeStatus { initial, loading, loaded, failure }

final class PassengerHomeState extends Equatable {
  const PassengerHomeState({
    this.status = PassengerHomeStatus.initial,
    this.profile,
    this.errorMessage = '',
  });

  final PassengerHomeStatus status;
  final PassengerProfileModel? profile;
  final String errorMessage;

  PassengerHomeState copyWith({
    PassengerHomeStatus? status,
    PassengerProfileModel? profile,
    String? errorMessage,
  }) {
    return PassengerHomeState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
