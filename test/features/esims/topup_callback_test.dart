import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/application/topup_callback.dart';

void main() {
  group('isTopupCallbackUrl', () {
    test('matches the real web terminal redirect for this esim', () {
      final uri = Uri.parse('https://triptel.co/my-esims/esim-1?topup=success');

      expect(isTopupCallbackUrl(uri, 'esim-1'), isTrue);
    });

    test('matches regardless of host (no hardcoded host, Rules.md)', () {
      final uri =
          Uri.parse('https://beta.triptel.co/my-esims/esim-1?topup=failed');

      expect(isTopupCallbackUrl(uri, 'esim-1'), isTrue);
    });

    test('does not match a different esim id', () {
      final uri = Uri.parse('https://triptel.co/my-esims/esim-2?topup=success');

      expect(isTopupCallbackUrl(uri, 'esim-1'), isFalse);
    });

    test('does not match a normal navigation URL (no topup param)', () {
      final uri = Uri.parse('https://shurjopay.example.invalid/checkout');

      expect(isTopupCallbackUrl(uri, 'esim-1'), isFalse);
    });
  });

  group('topupCallbackFailed', () {
    test('true for ?topup=failed', () {
      expect(topupCallbackFailed(Uri.parse('https://t.co/x?topup=failed')),
          isTrue);
    });

    test('false for ?topup=success', () {
      expect(topupCallbackFailed(Uri.parse('https://t.co/x?topup=success')),
          isFalse);
    });
  });
}
