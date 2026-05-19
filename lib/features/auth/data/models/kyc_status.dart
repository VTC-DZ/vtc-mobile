enum KycStatus {
  none,
  pending,
  approved,
  rejected;

  static KycStatus fromString(String? value) {
    return switch (value?.toUpperCase()) {
      'APPROVED' => KycStatus.approved,
      'PENDING' => KycStatus.pending,
      'REJECTED' => KycStatus.rejected,
      _ => KycStatus.none,
    };
  }
}
