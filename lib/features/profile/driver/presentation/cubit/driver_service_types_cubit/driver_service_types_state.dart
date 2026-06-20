import 'package:equatable/equatable.dart';

import '../../../../../ride/shared/models/shared_ride_models.dart';

enum DriverServiceTypesStatus { init, loading, success, failed }

final class DriverServiceTypesState extends Equatable {
  const DriverServiceTypesState({
    this.status = DriverServiceTypesStatus.init,
    this.activeTypes = const {},
    this.pendingType,
    this.errorMessage = '',
  });

  final DriverServiceTypesStatus status;
  final Set<ServiceType> activeTypes;

  /// The type whose request is currently in flight (drives the per-row spinner).
  final ServiceType? pendingType;
  final String errorMessage;

  bool isEnabled(ServiceType type) => activeTypes.contains(type);

  bool isPending(ServiceType type) =>
      status == DriverServiceTypesStatus.loading && pendingType == type;

  DriverServiceTypesState copyWith({
    DriverServiceTypesStatus? status,
    Set<ServiceType>? activeTypes,
    ServiceType? pendingType,
    bool clearPending = false,
    String? errorMessage,
  }) {
    return DriverServiceTypesState(
      status: status ?? this.status,
      activeTypes: activeTypes ?? this.activeTypes,
      pendingType: clearPending ? null : (pendingType ?? this.pendingType),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, activeTypes, pendingType, errorMessage];
}
