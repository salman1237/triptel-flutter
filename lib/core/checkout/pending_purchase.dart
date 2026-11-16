/// FR-106: a guest's in-progress purchase, persisted before sending them to
/// login/register/Google, so checkout can resume afterward. Only the id is
/// kept for the product (not the whole [Product] object) since it must
/// survive an app restart and a re-fetch (`GET /catalog/products/{id}`)
/// also catches a product that's since gone inactive.
class PendingPurchase {
  const PendingPurchase({
    required this.productId,
    required this.countryName,
    this.discountCode,
  });

  final String productId;
  final String countryName;
  final String? discountCode;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'countryName': countryName,
        if (discountCode != null) 'discountCode': discountCode,
      };

  factory PendingPurchase.fromJson(Map<String, dynamic> json) =>
      PendingPurchase(
        productId: json['productId'] as String,
        countryName: json['countryName'] as String,
        discountCode: json['discountCode'] as String?,
      );
}
