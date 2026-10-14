import 'package:equatable/equatable.dart';

import '../../../../profile/shared/data/models/kyc_status.dart';
import '../../../../profile/shared/data/models/passenger_profile_model.dart';
import '../../../data/models/kyc_status_result.dart';

enum KycStatusViewStatus { initial, loading, success, failure }

final class KycStatusState extends Equatable {
  const KycStatusState({
    this.status = KycStatusViewStatus.initial,
    this.kycResult,
    this.profile,
    this.errorMessage = '',
  });

  final KycStatusViewStatus status;
  final KycStatusResult? kycResult;

  /// The account, loaded for a rejected or revoked application only.
  final PassengerProfileModel? profile;
  final String errorMessage;

  bool get isPending => kycResult?.kycStatus == KycStatus.pending;
  bool get isApproved => kycResult?.kycStatus == KycStatus.approved;
  bool get isRejected => kycResult?.kycStatus == KycStatus.rejected;
  bool get isRevoked => kycResult?.kycStatus == KycStatus.revoked;
  bool get isNone => kycResult?.kycStatus == KycStatus.none;

  /// Whether the server accepts a new application: after a rejection, or
  /// after a revocation that asks for one (`requiresRekyc`).
  bool get canResubmit =>
      isRejected || (isRevoked && (profile?.driverRequiresRekyc ?? false));

  KycStatusState copyWith({
    KycStatusViewStatus? status,
    KycStatusResult? kycResult,
    PassengerProfileModel? profile,
    String? errorMessage,
  }) {
    return KycStatusState(
      status: status ?? this.status,
      kycResult: kycResult ?? this.kycResult,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, kycResult, profile, errorMessage];
}
