import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/deeplink/deep_link.dart';

void main() {
  group('parseDeepLink', () {
    test('parses a payment callback with its query params', () {
      final link = parseDeepLink(
          Uri.parse('triptel://payment-callback?order_id=abc&status=SUCCESS'));
      expect(link, isA<PaymentCallbackDeepLink>());
      expect((link as PaymentCallbackDeepLink).params,
          {'order_id': 'abc', 'status': 'SUCCESS'});
    });

    test('parses a tracking link on triptel.co', () {
      final link = parseDeepLink(Uri.parse('https://triptel.co/track/TOK123'));
      expect(link, isA<TrackingDeepLink>());
      expect((link as TrackingDeepLink).token, 'TOK123');
    });

    test('parses a tracking link on beta.triptel.co', () {
      final link =
          parseDeepLink(Uri.parse('https://beta.triptel.co/track/TOK456'));
      expect(link, isA<TrackingDeepLink>());
      expect((link as TrackingDeepLink).token, 'TOK456');
    });

    test('an unrelated https link is unknown', () {
      final link = parseDeepLink(Uri.parse('https://triptel.co/'));
      expect(link, isA<UnknownDeepLink>());
    });

    test('a track-shaped path on an untrusted host is unknown', () {
      final link =
          parseDeepLink(Uri.parse('https://evil.example/track/TOK123'));
      expect(link, isA<UnknownDeepLink>());
    });

    test('triptel:// with a different host is unknown', () {
      final link = parseDeepLink(Uri.parse('triptel://something-else'));
      expect(link, isA<UnknownDeepLink>());
    });
  });

  group('extractReferralCode', () {
    test('reads ?ref=CODE', () {
      expect(extractReferralCode(Uri.parse('https://triptel.co/?ref=ABC123')),
          'ABC123');
    });

    test('works alongside a tracking link', () {
      expect(
          extractReferralCode(
              Uri.parse('https://triptel.co/track/TOK?ref=ABC123')),
          'ABC123');
    });

    test('is null when absent', () {
      expect(extractReferralCode(Uri.parse('https://triptel.co/track/TOK')),
          isNull);
    });

    test('is null when present but empty', () {
      expect(
          extractReferralCode(Uri.parse('https://triptel.co/?ref=')), isNull);
    });
  });
}
