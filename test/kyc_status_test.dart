import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/features/profile/shared/data/models/kyc_status.dart';

void main() {
  group('KycStatus.fromString', () {
    test('parses every server value', () {
      expect(KycStatus.fromString('NONE'), KycStatus.none);
      expect(KycStatus.fromString('PENDING'), KycStatus.pending);
      expect(KycStatus.fromString('APPROVED'), KycStatus.approved);
      expect(KycStatus.fromString('REJECTED'), KycStatus.rejected);
      expect(KycStatus.fromString('REVOKED'), KycStatus.revoked);
    });

    test('ignores case', () {
      expect(KycStatus.fromString('revoked'), KycStatus.revoked);
      expect(KycStatus.fromString('Approved'), KycStatus.approved);
    });

    test('maps null and unknown values to none', () {
      expect(KycStatus.fromString(null), KycStatus.none);
      expect(KycStatus.fromString(''), KycStatus.none);
      expect(KycStatus.fromString('SOMETHING_NEW'), KycStatus.none);
    });
  });
}
