/// FR-408/API.md section 7: the ShurjoPay eSIM top-up flow's terminal
/// redirect goes to the **web** -- `.../my-esims/{esim_id}?topup=success|
/// failed` -- not a custom scheme like the first-purchase flow. Matched by
/// path+query only, no hardcoded host (Rules.md: beta API only), so a
/// WebView's navigation delegate can intercept it before it actually loads.
bool isTopupCallbackUrl(Uri uri, String esimId) =>
    uri.path.endsWith('/my-esims/$esimId') &&
    uri.queryParameters.containsKey('topup');

bool topupCallbackFailed(Uri uri) => uri.queryParameters['topup'] == 'failed';
