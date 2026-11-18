import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/application/home_usage_card_shape.dart';
import 'package:triptel/features/esims/data/models/my_esim.dart';

final _now = DateTime.utc(2026, 11, 18);

MyEsim _esim({
  required String id,
  String status = 'RELEASED',
  DateTime? activatedAt,
  DateTime? expiresAt,
}) =>
    MyEsim(
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
      activatedAt: activatedAt,
      expiresAt: expiresAt,
      isBeneficiary: false,
    );

void main() {
  test(
      'picks the first genuinely activated, not-yet-expired eSIM '
      '(list is newest-first) -- status is deliberately ignored, since it '
      'never updates for eSIM Access profiles (see doc comment)', () {
    final esims = [
      _esim(id: '1'), // never installed: activatedAt null
      _esim(
        id: '2',
        status: 'RELEASED', // the real, known-stale case
        activatedAt: DateTime.utc(2026, 11, 10),
        expiresAt: DateTime.utc(2026, 11, 25),
      ),
      _esim(
        id: '3',
        activatedAt: DateTime.utc(2026, 11, 5),
        expiresAt: DateTime.utc(2026, 11, 30),
      ),
    ];

    expect(activeEsimForHomeCard(esims, _now)?.id, '2');
  });

  test('skips a not-yet-installed eSIM (activatedAt null)', () {
    final esims = [_esim(id: '1', activatedAt: null)];

    expect(activeEsimForHomeCard(esims, _now), isNull);
  });

  test('skips an activated eSIM that has already expired', () {
    final esims = [
      _esim(
        id: '1',
        activatedAt: DateTime.utc(2026, 11, 1),
        expiresAt: DateTime.utc(2026, 11, 8),
      ),
    ];

    expect(activeEsimForHomeCard(esims, _now), isNull);
  });

  test(
      'an activated eSIM with no expiresAt still counts (unlimited-days '
      'plan, or the backend simply hasn\'t set one)', () {
    final esims = [
      _esim(id: '1', activatedAt: DateTime.utc(2026, 11, 1), expiresAt: null),
    ];

    expect(activeEsimForHomeCard(esims, _now)?.id, '1');
  });

  test('returns null when there are no eSIMs at all', () {
    expect(activeEsimForHomeCard(const [], _now), isNull);
  });
}
