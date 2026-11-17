import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/kyc/application/kyc_status_label.dart';
import 'package:triptel/features/kyc/data/models/kyc_status.dart';

void main() {
  test('KycStatus.fromJson parses the real not-submitted shape', () {
    final status =
        KycStatus.fromJson(const {'submitted': false, 'status': null});

    expect(status.submitted, isFalse);
    expect(status.status, isNull);
  });

  test('KycStatus.fromJson parses the real rejected shape', () {
    final status = KycStatus.fromJson(const {
      'submitted': true,
      'status': 'REJECTED',
      'rejection_reason': 'Blurry photo',
      'submitted_at': '2026-11-01T00:00:00Z',
    });

    expect(status.submitted, isTrue);
    expect(status.status, 'REJECTED');
    expect(status.rejectionReason, 'Blurry photo');
    expect(status.submittedAt, DateTime.parse('2026-11-01T00:00:00Z'));
  });

  test('kycStatusLabel: not submitted is "Not verified"', () {
    expect(kycStatusLabel(const KycStatus(submitted: false)).label,
        'Not verified');
  });

  test('kycStatusLabel: PENDING/APPROVED/REJECTED map to real labels', () {
    expect(
        kycStatusLabel(const KycStatus(submitted: true, status: 'PENDING'))
            .label,
        'Pending');
    expect(
        kycStatusLabel(const KycStatus(submitted: true, status: 'APPROVED'))
            .label,
        'Verified');
    expect(
        kycStatusLabel(const KycStatus(submitted: true, status: 'REJECTED'))
            .label,
        'Rejected');
  });
}
