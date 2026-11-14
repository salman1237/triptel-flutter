/// FR-307/API.md §9: the final redirect for the eSIM-purchase ShurjoPay
/// flow is `triptel://payment-callback?order=<id>` or
/// `triptel://payment-callback?payment=failed&reason=<r>`. This is a hint,
/// never proof -- the caller always re-polls the real order afterward.
class ShurjoPayCallback {
  const ShurjoPayCallback(
      {required this.orderId, required this.failed, this.reason});

  final String? orderId;
  final bool failed;
  final String? reason;
}

/// Whether [uri] is the ShurjoPay eSIM-purchase terminal redirect that a
/// WebView's navigation delegate should intercept rather than load.
bool isShurjoPayCallbackUrl(Uri uri) =>
    uri.scheme == 'triptel' && uri.host == 'payment-callback';

ShurjoPayCallback parseShurjoPayCallback(Uri uri) => ShurjoPayCallback(
      orderId: uri.queryParameters['order'],
      failed: uri.queryParameters['payment'] == 'failed',
      reason: uri.queryParameters['reason'],
    );
