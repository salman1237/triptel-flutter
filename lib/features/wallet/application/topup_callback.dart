/// FR-603/API.md section 5: the ShurjoPay wallet top-up flow's terminal
/// redirect goes to the **web** -- `.../wallet?topup=success|failed|
/// cancelled` -- not a custom scheme. Matched by path+query only, no
/// hardcoded host (Rules.md: beta API only), so a WebView's navigation
/// delegate can intercept it before it actually loads. `cancelled` is the
/// gateway's own direct redirect if the customer backs out on ShurjoPay's
/// hosted page before our backend callback ever runs (confirmed against
/// `SHURJOPAY_CANCEL_URL` in the backend config) -- treated the same as a
/// failure here, since either way nothing was credited.
bool isWalletTopupCallbackUrl(Uri uri) =>
    uri.path.endsWith('/wallet') && uri.queryParameters.containsKey('topup');

bool walletTopupCallbackFailed(Uri uri) =>
    uri.queryParameters['topup'] != 'success';
