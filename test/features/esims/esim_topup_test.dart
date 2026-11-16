import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/data/models/esim_topup.dart';
import 'package:triptel/features/esims/data/models/topup_shurjopay_checkout.dart';

void main() {
  test(
      'EsimTopup.fromJson parses the documented POST /esims/{id}/topup '
      'shape (API.md section 7)', () {
    final topup = EsimTopup.fromJson(const {
      'id': 'topup-1',
      'esim_profile_id': 'esim-1',
      'package_code': 'TOPUP_JC063',
      'title': 'Japan 1GB 7Days',
      'data_amount_gb': '1.00',
      'validity_days': 7,
      'retail_price': '2.10',
      'currency': 'USD',
      'status': 'COMPLETED',
      'created_at': '2026-11-17T00:00:00Z',
      'completed_at': '2026-11-17T00:00:05Z',
    });

    expect(topup.packageCode, 'TOPUP_JC063');
    expect(topup.dataAmountGb, 1.0);
    expect(topup.validityDays, 7);
    // API.md §0.2: treat every amount as EUR regardless of the "currency"
    // label.
    expect(topup.retailPrice.eurCents, 210);
    expect(topup.status, 'COMPLETED');
    expect(topup.failed, isFalse);
    expect(topup.completedAt, isNotNull);
  });

  test('EsimTopup.failed is true only for an explicit FAILED status', () {
    final failed = EsimTopup.fromJson(const {
      'id': 'topup-1',
      'esim_profile_id': 'esim-1',
      'package_code': 'TOPUP_JC063',
      'title': 'Japan 1GB 7Days',
      'data_amount_gb': '1.00',
      'validity_days': 7,
      'retail_price': '2.10',
      'status': 'FAILED',
      'created_at': '2026-11-17T00:00:00Z',
    });

    expect(failed.failed, isTrue);
    expect(failed.completedAt, isNull);
  });

  test(
      'TopupShurjoPayCheckout.fromJson accepts both checkout_url and '
      'checkoutUrl casings (API.md: "also try checkoutUrl")', () {
    final snake = TopupShurjoPayCheckout.fromJson(const {
      'topup_id': 'topup-1',
      'checkout_url': 'https://shurjopay.example.invalid/checkout',
    });
    final camel = TopupShurjoPayCheckout.fromJson(const {
      'topup_id': 'topup-1',
      'checkoutUrl': 'https://shurjopay.example.invalid/checkout',
    });

    expect(snake.checkoutUrl, 'https://shurjopay.example.invalid/checkout');
    expect(camel.checkoutUrl, 'https://shurjopay.example.invalid/checkout');
  });
}
