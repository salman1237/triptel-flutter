/// `POST /payments/shurjopay/topup` response (API.md §5). The backend
/// returns ShurjoPay's own raw payload -- only `checkout_url` (or the
/// alternate `checkoutUrl` casing API.md calls out) is documented/needed.
class TopupCheckout {
  const TopupCheckout({required this.checkoutUrl});

  final String checkoutUrl;

  factory TopupCheckout.fromJson(Map<String, dynamic> json) => TopupCheckout(
        checkoutUrl: (json['checkout_url'] ?? json['checkoutUrl']) as String,
      );
}
