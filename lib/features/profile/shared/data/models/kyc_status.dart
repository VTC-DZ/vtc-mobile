/// Driver KYC state, from `kycStatus` in `GET /api/driver/kyc/status` and the
/// `driver` summary of `GET /api/me/profile`.
enum KycStatus {
  none,
  pending,
  approved,
  rejected,

  /// An approved driver whose access was withdrawn by an admin.
  revoked;

  static KycStatus fromString(String? value) {
    return switch (value?.toUpperCase()) {
      'APPROVED' => KycStatus.approved,
      'PENDING' => KycStatus.pending,
      'REJECTED' => KycStatus.rejected,
      'REVOKED' => KycStatus.revoked,
      _ => KycStatus.none,
    };
  }
}
