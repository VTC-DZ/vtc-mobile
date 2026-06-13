import 'package:equatable/equatable.dart';

enum DriverAvailabilityStatus { init, loading, success, failed }

final class DriverAvailabilityState extends Equatable {
  const DriverAvailabilityState({
    this.status = DriverAvailabilityStatus.init,
    this.isOnline = false,
  });

  final DriverAvailabilityStatus status;
  final bool isOnline;

  DriverAvailabilityState copyWith({
    DriverAvailabilityStatus? status,
    bool? isOnline,
  }) {
    return DriverAvailabilityState(
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [status, isOnline];
}
