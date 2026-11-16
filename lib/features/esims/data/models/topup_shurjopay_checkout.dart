/// `POST /payments/shurjopay/esim-topup-initiate` response (API.md section
/// 7). Same tolerant `checkout_url`/`checkoutUrl` casing as the
/// first-purchase equivalent (`ShurjoPayCheckout`) -- the gateway
/// payload's exact shape beyond `checkout_url` isn't documented.
class TopupShurjoPayCheckout {
  const TopupShurjoPayCheckout(
      {required this.topupId, required this.checkoutUrl});

  final String topupId;
  final String checkoutUrl;

  factory TopupShurjoPayCheckout.fromJson(Map<String, dynamic> json) =>
      TopupShurjoPayCheckout(
        topupId: json['topup_id'] as String,
        checkoutUrl: (json['checkout_url'] ?? json['checkoutUrl']) as String,
      );
}
