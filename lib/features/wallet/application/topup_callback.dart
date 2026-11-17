/// FR-603/FR-605/API.md section 5: the ShurjoPay wallet top-up flow's
/// terminal redirect goes to the **web** -- `.../wallet?topup=success|
/// failed|cancelled&reason=...` -- not a custom scheme. Matched by
/// path+query only, no hardcoded host (Rules.md: beta API only), so a
/// WebView's navigation delegate can intercept it before it actually loads.
/// `cancelled` is the gateway's own direct redirect if the customer backs
/// out on ShurjoPay's hosted page before our backend callback ever runs
/// (confirmed against `SHURJOPAY_CANCEL_URL` in the backend config) --
/// carries no `reason` (the gateway never ran our callback to produce one).
bool isWalletTopupCallbackUrl(Uri uri) =>
    uri.path.endsWith('/wallet') && uri.queryParameters.containsKey('topup');

enum WalletTopupStatus { success, failed, cancelled }

class WalletTopupResult {
  const WalletTopupResult({required this.status, this.reason});

  final WalletTopupStatus status;
  final String? reason;
}

WalletTopupResult parseWalletTopupCallback(Uri uri) {
  // ShurjoPay's own sandbox "cancel this transaction" link malforms its
  // query string -- confirmed live on-device: it appends "?order_id=..."
  // after "cancelled" instead of "&order_id=...", so the raw topup value
  // comes through as "cancelled?order_id=NOKBETA...", not a clean
  // "cancelled". Taking the leading token before any "?" handles both the
  // well-formed values our own backend sends and this malformed one.
  final topup = (uri.queryParameters['topup'] ?? '').split('?').first;
  final status = switch (topup) {
    'success' => WalletTopupStatus.success,
    'cancelled' => WalletTopupStatus.cancelled,
    _ => WalletTopupStatus.failed,
  };
  return WalletTopupResult(
      status: status, reason: uri.queryParameters['reason']);
}

/// Human labels for the wallet top-up callback's documented `reason` codes
/// (confirmed by reading `app/api/v1/payments.py`'s `_fail(...)` calls on
/// the default `/wallet` redirect path directly). Falls back to the raw
/// code for anything undocumented, same precedent as `ledgerReferenceLabel`.
const Map<String, String> walletTopupFailureReasons = {
  'not_paid': "The payment wasn't completed.",
  'unexpected_response': "We couldn't confirm this payment with the gateway.",
  'unknown_order': "This payment couldn't be matched to your request.",
  'malformed_order': 'Something went wrong identifying your payment.',
  'unknown_user': "We couldn't find your account for this payment.",
  'no_wallet': "We couldn't find a wallet to credit.",
};

String walletTopupFailureMessage(String? reason) {
  if (reason == null) return 'Top-up failed.';
  return walletTopupFailureReasons[reason] ?? 'Top-up failed: $reason';
}
