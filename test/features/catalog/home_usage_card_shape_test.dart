import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/application/home_usage_card_shape.dart';
import 'package:triptel/features/esims/data/models/my_esim.dart';

MyEsim _esim({required String id, required String status}) => MyEsim(
      id: id,
      orderNo: 'ORD-$id',
      productTitle: 'Japan 1GB 7Days',
      dataAmountGb: 1,
      isUnlimited: false,
      validityDays: 7,
      iccid: '',
      lpaString: '',
      qrCodeData: '',
      smdpAddress: '',
      status: status,
      isMockFallback: false,
      createdAt: DateTime.utc(2026, 11, 1),
      activatedAt: null,
      expiresAt: null,
      isBeneficiary: false,
    );

void main() {
  test('picks the first ACTIVE or INSTALLED eSIM (list is newest-first)', () {
    final esims = [
      _esim(id: '1', status: 'RELEASED'),
      _esim(id: '2', status: 'ACTIVE'),
      _esim(id: '3', status: 'INSTALLED'),
    ];

    expect(activeEsimForHomeCard(esims)?.id, '2');
  });

  test('skips RELEASED/ALLOCATED and terminal statuses', () {
    final esims = [
      _esim(id: '1', status: 'RELEASED'),
      _esim(id: '2', status: 'ALLOCATED'),
      _esim(id: '3', status: 'SUSPENDED'),
      _esim(id: '4', status: 'REVOKED'),
      _esim(id: '5', status: 'CANCELLED'),
      _esim(id: '6', status: 'EXPIRED'),
    ];

    expect(activeEsimForHomeCard(esims), isNull);
  });

  test('returns null when there are no eSIMs at all', () {
    expect(activeEsimForHomeCard(const []), isNull);
  });
}
