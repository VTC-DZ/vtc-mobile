import 'package:equatable/equatable.dart';

import '../../../data/repo/driver_repository.dart';

enum KycStatusViewStatus { initial, loading, success, failure }

final class KycStatusState extends Equatable {
  const KycStatusState({
    this.status = KycStatusViewStatus.initial,
    this.kycResult,
    this.errorMessage = '',
  });

  final KycStatusViewStatus status;
  final KycStatusResult? kycResult;
  final String errorMessage;

  bool get isPending => kycResult?.kycStatus == 'PENDING';
  bool get isApproved => kycResult?.kycStatus == 'APPROVED';
  bool get isRejected => kycResult?.kycStatus == 'REJECTED';
  bool get isNone => kycResult?.kycStatus == 'NONE';

  KycStatusState copyWith({
    KycStatusViewStatus? status,
    KycStatusResult? kycResult,
    String? errorMessage,
  }) {
    return KycStatusState(
      status: status ?? this.status,
      kycResult: kycResult ?? this.kycResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, kycResult, errorMessage];
}
