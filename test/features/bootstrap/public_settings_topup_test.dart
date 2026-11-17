import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';

void main() {
  test(
      'parses the real beta topup_min/topup_max (API.md section 1, '
      '"0.01"/"2000.00" EUR)', () {
    final settings = PublicSettings.fromJson(const {
      'platform_name': 'Triptel',
      'maintenance_mode': false,
      'default_currency': 'EUR',
      'topup_min': '0.01',
      'topup_max': '2000.00',
    });

    expect(settings.topupMin.eurCents, 1);
    expect(settings.topupMax.eurCents, 200000);
  });

  test('falls back to a sane default when topup_min/max are absent', () {
    final settings = PublicSettings.fromJson(const {
      'platform_name': 'Triptel',
      'maintenance_mode': false,
      'default_currency': 'EUR',
    });

    expect(settings.topupMin.eurCents, 1);
    expect(settings.topupMax.eurCents, 200000);
  });
}
