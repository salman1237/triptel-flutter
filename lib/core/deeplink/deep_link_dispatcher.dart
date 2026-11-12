import 'deep_link.dart';

/// Parses [uri] and calls the matching handler, plus [onReferral] whenever a
/// `?ref=` is present regardless of link type. Pure and synchronous so the
/// real `app_links`/`go_router`/prefs wiring (thin, untested glue) can stay
/// in the provider layer while this stays unit-testable.
void handleDeepLink(
  Uri uri, {
  required void Function(Map<String, String> params) onPaymentCallback,
  required void Function(String token) onTracking,
  required void Function(Uri uri) onUnknown,
  required void Function(String code) onReferral,
}) {
  final link = parseDeepLink(uri);
  switch (link) {
    case PaymentCallbackDeepLink(:final params):
      onPaymentCallback(params);
    case TrackingDeepLink(:final token):
      onTracking(token);
    case UnknownDeepLink(:final uri):
      onUnknown(uri);
  }

  final referralCode = extractReferralCode(uri);
  if (referralCode != null) onReferral(referralCode);
}
