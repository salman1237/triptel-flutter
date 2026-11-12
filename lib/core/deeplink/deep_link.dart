/// FR-007: the parsed shape of an incoming link, kept as a pure sealed type
/// so parsing/dispatch is unit-testable without the `app_links` plugin
/// (Architecture.md: business rules in plain Dart).
sealed class DeepLink {
  const DeepLink();
}

/// `triptel://payment-callback?...` — a gateway returning from a payment.
class PaymentCallbackDeepLink extends DeepLink {
  const PaymentCallbackDeepLink(this.params);
  final Map<String, String> params;
}

/// `https://triptel.co/track/<token>` — public order tracking (FR-501).
class TrackingDeepLink extends DeepLink {
  const TrackingDeepLink(this.token);
  final String token;
}

/// Anything else (home page, unrecognised path, etc.) — ignored for routing,
/// but a `?ref=` on it is still honoured by [extractReferralCode].
class UnknownDeepLink extends DeepLink {
  const UnknownDeepLink(this.uri);
  final Uri uri;
}

const _trackingHosts = {'triptel.co', 'beta.triptel.co'};

/// Parses an incoming [uri] per API.md/FR-007: `triptel://payment-callback`
/// for payments, `https://triptel.co/track/<token>` for tracking links.
DeepLink parseDeepLink(Uri uri) {
  if (uri.scheme == 'triptel' && uri.host == 'payment-callback') {
    return PaymentCallbackDeepLink(uri.queryParameters);
  }
  if (_trackingHosts.contains(uri.host) &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments[0] == 'track') {
    return TrackingDeepLink(uri.pathSegments[1]);
  }
  return UnknownDeepLink(uri);
}

/// A `?ref=CODE` query param can ride along on any link (track or not);
/// best-effort per FR-007/FR-803, never blocks the rest of the link.
String? extractReferralCode(Uri uri) {
  final code = uri.queryParameters['ref'];
  return (code == null || code.isEmpty) ? null : code;
}
