import 'package:equatable/equatable.dart';

import '../../../data/models/kyc_status.dart';
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

  bool get isPending => kycResult?.kycStatus == KycStatus.pending;
  bool get isApproved => kycResult?.kycStatus == KycStatus.approved;
  bool get isRejected => kycResult?.kycStatus == KycStatus.rejected;
  bool get isNone => kycResult?.kycStatus == KycStatus.none;

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
