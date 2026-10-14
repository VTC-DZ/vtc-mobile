import 'package:equatable/equatable.dart';

import '../../../profile/shared/data/models/kyc_status.dart';

/// `KycSubmitResponse` from `POST /api/driver/kyc/submit`.
final class KycSubmitResult extends Equatable {
  const KycSubmitResult({required this.submissionId, required this.status});

  factory KycSubmitResult.fromJson(Map<String, dynamic> json) =>
      KycSubmitResult(
        submissionId: json['submissionId'] as String? ?? '',
        status: json['status'] as String? ?? '',
      );

  final String submissionId;
  final String status;

  @override
  List<Object?> get props => [submissionId, status];
}

/// `KycStatusResponse` from `GET /api/driver/kyc/status`: the driver's KYC
/// state plus the latest submission, when there is one.
final class KycStatusResult extends Equatable {
  const KycStatusResult({
    required this.kycStatus,
    this.submissionId,
    this.submissionStatus,
    this.resubmissionNote,
    this.submittedAt,
    this.reviewedAt,
  });

  factory KycStatusResult.fromJson(Map<String, dynamic> json) {
    final submission = json['submission'] as Map<String, dynamic>?;
    return KycStatusResult(
      kycStatus: KycStatus.fromString(json['kycStatus'] as String?),
      submissionId: submission?['id'] as String?,
      submissionStatus: submission?['status'] as String?,
      resubmissionNote: submission?['resubmissionNote'] as String?,
      submittedAt: _parseDate(submission?['submittedAt'] as String?),
      reviewedAt: _parseDate(submission?['reviewedAt'] as String?),
    );
  }

  final KycStatus kycStatus;
  final String? submissionId;
  final String? submissionStatus;

  /// The reviewer's note on a rejected submission.
  final String? resubmissionNote;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  static DateTime? _parseDate(String? value) =>
      value == null ? null : DateTime.tryParse(value);

  @override
  List<Object?> get props => [
        kycStatus,
        submissionId,
        submissionStatus,
        resubmissionNote,
        submittedAt,
        reviewedAt,
      ];
}
