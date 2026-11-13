import 'country.dart';
import 'product.dart';

/// `GET /catalog/destinations/{slug}` response (API.md §3).
class Destination {
  const Destination({required this.country, required this.products});

  final Country country;
  final List<Product> products;

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
        country: Country.fromJson(json['country'] as Map<String, dynamic>),
        products: (json['products'] as List)
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
