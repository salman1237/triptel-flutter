import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/widgets/status_chip.dart';
import 'package:triptel/features/esims/application/esim_card_shape.dart';
import 'package:triptel/features/esims/data/models/my_esim.dart';

MyEsim _esim({
  double dataAmountGb = 1,
  bool isUnlimited = false,
  int validityDays = 7,
  String status = 'RELEASED',
  DateTime? activatedAt,
  DateTime? expiresAt,
  bool isBeneficiary = false,
}) =>
    MyEsim(
      id: 'esim-1',
      orderNo: 'ORD-TEST-1',
      productTitle: 'Test Plan',
      dataAmountGb: dataAmountGb,
      isUnlimited: isUnlimited,
      validityDays: validityDays,
      iccid: '',
      lpaString: '',
      qrCodeData: '',
      smdpAddress: '',
      status: status,
      isMockFallback: false,
      createdAt: DateTime.utc(2026, 1, 1),
      activatedAt: activatedAt,
      expiresAt: expiresAt,
      isBeneficiary: isBeneficiary,
    );

void main() {
  group('esimDataLabel', () {
    test('unlimited', () {
      expect(esimDataLabel(_esim(isUnlimited: true)), 'Unlimited');
    });

    test('below 1GB shows MB', () {
      expect(esimDataLabel(_esim(dataAmountGb: 0.1)), '100 MB');
    });

    test('1GB and above shows GB, trimmed', () {
      expect(esimDataLabel(_esim(dataAmountGb: 3)), '3 GB');
      expect(esimDataLabel(_esim(dataAmountGb: 1.5)), '1.5 GB');
    });
  });

  group('esimValidityLabel', () {
    test('not yet installed', () {
      expect(esimValidityLabel(_esim(activatedAt: null)),
          'Validity starts on install');
    });

    test('activated with an expiry date', () {
      expect(
          esimValidityLabel(_esim(
            activatedAt: DateTime.utc(2026, 11, 11),
            expiresAt: DateTime.utc(2026, 12, 2),
          )),
          'Expires Dec 2, 2026');
    });

    test('activated with no expiry falls back to validity days', () {
      expect(
          esimValidityLabel(_esim(
            activatedAt: DateTime.utc(2026, 11, 11),
            expiresAt: null,
            validityDays: 7,
          )),
          '7-day validity');
    });
  });

  group('esimOwnershipLabel', () {
    test('beneficiary -> bought for me', () {
      expect(esimOwnershipLabel(_esim(isBeneficiary: true)), 'Bought for me');
    });

    test('buyer -> bought by me', () {
      expect(esimOwnershipLabel(_esim(isBeneficiary: false)), 'Bought by me');
    });
  });

  group('esimStatusChip', () {
    test('maps known statuses to the documented tones', () {
      expect(esimStatusChip('ACTIVE').tone, StatusTone.success);
      expect(esimStatusChip('INSTALLED').tone, StatusTone.success);
      expect(esimStatusChip('RELEASED').tone, StatusTone.info);
      expect(esimStatusChip('ALLOCATED').tone, StatusTone.warning);
      expect(esimStatusChip('SUSPENDED').tone, StatusTone.danger);
      expect(esimStatusChip('REVOKED').tone, StatusTone.danger);
      expect(esimStatusChip('CANCELLED').tone, StatusTone.danger);
      expect(esimStatusChip('EXPIRED').tone, StatusTone.danger);
    });

    test(
        'RELEASED says "Ready to install", never "Not installed" -- this '
        "list's own status field doesn't reliably track real install "
        'state (confirmed live against the beta backend)', () {
      expect(esimStatusChip('RELEASED').label, 'Ready to install');
    });

    test('unknown status falls back to a warning chip with the raw label', () {
      final chip = esimStatusChip('SOMETHING_NEW');
      expect(chip.label, 'SOMETHING_NEW');
      expect(chip.tone, StatusTone.warning);
    });
  });
}
