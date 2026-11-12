import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/deeplink/deep_link_dispatcher.dart';

void main() {
  group('handleDeepLink', () {
    test('a payment callback calls onPaymentCallback only', () {
      Map<String, String>? gotParams;
      var otherCalls = 0;

      handleDeepLink(
        Uri.parse('triptel://payment-callback?order_id=abc'),
        onPaymentCallback: (params) => gotParams = params,
        onTracking: (_) => otherCalls++,
        onUnknown: (_) => otherCalls++,
        onReferral: (_) => otherCalls++,
      );

      expect(gotParams, {'order_id': 'abc'});
      expect(otherCalls, 0);
    });

    test('a tracking link calls onTracking only', () {
      String? gotToken;
      var otherCalls = 0;

      handleDeepLink(
        Uri.parse('https://triptel.co/track/TOK123'),
        onPaymentCallback: (_) => otherCalls++,
        onTracking: (token) => gotToken = token,
        onUnknown: (_) => otherCalls++,
        onReferral: (_) => otherCalls++,
      );

      expect(gotToken, 'TOK123');
      expect(otherCalls, 0);
    });

    test('an unrelated link calls onUnknown only', () {
      Uri? gotUri;
      var otherCalls = 0;

      handleDeepLink(
        Uri.parse('https://triptel.co/'),
        onPaymentCallback: (_) => otherCalls++,
        onTracking: (_) => otherCalls++,
        onUnknown: (uri) => gotUri = uri,
        onReferral: (_) => otherCalls++,
      );

      expect(gotUri, Uri.parse('https://triptel.co/'));
      expect(otherCalls, 0);
    });

    test('onReferral fires alongside the main handler when ?ref= is present',
        () {
      String? gotToken;
      String? gotReferral;

      handleDeepLink(
        Uri.parse('https://triptel.co/track/TOK123?ref=ABC'),
        onPaymentCallback: (_) {},
        onTracking: (token) => gotToken = token,
        onUnknown: (_) {},
        onReferral: (code) => gotReferral = code,
      );

      expect(gotToken, 'TOK123');
      expect(gotReferral, 'ABC');
    });

    test('onReferral does not fire when ?ref= is absent', () {
      var referralCalls = 0;

      handleDeepLink(
        Uri.parse('https://triptel.co/track/TOK123'),
        onPaymentCallback: (_) {},
        onTracking: (_) {},
        onUnknown: (_) {},
        onReferral: (_) => referralCalls++,
      );

      expect(referralCalls, 0);
    });
  });
}
