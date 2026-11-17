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

  group('parseWalletTopupCallback', () {
    test('success has no reason', () {
      final result = parseWalletTopupCallback(
          Uri.parse('https://triptel.co/wallet?topup=success'));
      expect(result.status, WalletTopupStatus.success);
      expect(result.reason, isNull);
    });

    test('failed carries the real reason code', () {
      final result = parseWalletTopupCallback(
          Uri.parse('https://triptel.co/wallet?topup=failed&reason=not_paid'));
      expect(result.status, WalletTopupStatus.failed);
      expect(result.reason, 'not_paid');
    });

    test('cancelled (the gateway\'s own direct redirect) has no reason', () {
      final result = parseWalletTopupCallback(
          Uri.parse('https://triptel.co/wallet?topup=cancelled'));
      expect(result.status, WalletTopupStatus.cancelled);
      expect(result.reason, isNull);
    });

    test('an unrecognized topup value is treated as failed', () {
      final result = parseWalletTopupCallback(
          Uri.parse('https://triptel.co/wallet?topup=something_new'));
      expect(result.status, WalletTopupStatus.failed);
    });

    test(
        "ShurjoPay's own sandbox cancel link malforms its query string "
        '("?order_id=..." instead of "&order_id=...") -- confirmed live '
        'on-device; still recognized as cancelled, not misparsed as failed',
        () {
      final result = parseWalletTopupCallback(Uri.parse(
          'https://triptel.co/wallet?topup=cancelled?order_id=NOKBETA6afbfd131620f'));
      expect(result.status, WalletTopupStatus.cancelled);
    });
  });

  group('walletTopupFailureMessage', () {
    test(
        'every documented reason code (payments.py _fail calls on the '
        '/wallet path) has a human message', () {
      const documented = [
        'not_paid',
        'unexpected_response',
        'unknown_order',
        'malformed_order',
        'unknown_user',
        'no_wallet',
      ];
      for (final reason in documented) {
        expect(walletTopupFailureMessage(reason), isNot('Top-up failed.'),
            reason: '$reason should have a specific human message');
      }
    });

    test('no reason at all falls back to a generic message', () {
      expect(walletTopupFailureMessage(null), 'Top-up failed.');
    });

    test('an undocumented future reason falls back to showing the raw code',
        () {
      expect(walletTopupFailureMessage('some_new_reason'),
          'Top-up failed: some_new_reason');
    });
  });
}
