import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/wallet/application/topup_callback.dart';

void main() {
  group('isWalletTopupCallbackUrl', () {
    test('recognizes the real backend redirect (API.md section 5)', () {
      expect(
          isWalletTopupCallbackUrl(
              Uri.parse('https://triptel.co/wallet?topup=success')),
          isTrue);
    });

    test('recognizes a failure redirect with a reason', () {
      expect(
          isWalletTopupCallbackUrl(Uri.parse(
              'https://triptel.co/wallet?topup=failed&reason=not_paid')),
          isTrue);
    });

    test('recognizes the gateway\'s own direct cancel redirect', () {
      expect(
          isWalletTopupCallbackUrl(
              Uri.parse('https://triptel.co/wallet?topup=cancelled')),
          isTrue);
    });

    test('does not match the wallet page without a topup query param', () {
      expect(isWalletTopupCallbackUrl(Uri.parse('https://triptel.co/wallet')),
          isFalse);
    });

    test('does not match a different path (e.g. the eSIM topup callback)', () {
      expect(
          isWalletTopupCallbackUrl(
              Uri.parse('https://triptel.co/my-esims/abc?topup=success')),
          isFalse);
    });
  });

  group('walletTopupCallbackFailed', () {
    test('false for topup=success', () {
      expect(
          walletTopupCallbackFailed(
              Uri.parse('https://triptel.co/wallet?topup=success')),
          isFalse);
    });

    test('true for topup=failed', () {
      expect(
          walletTopupCallbackFailed(
              Uri.parse('https://triptel.co/wallet?topup=failed')),
          isTrue);
    });

    test('true for topup=cancelled', () {
      expect(
          walletTopupCallbackFailed(
              Uri.parse('https://triptel.co/wallet?topup=cancelled')),
          isTrue);
    });
  });
}
