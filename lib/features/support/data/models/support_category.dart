/// `GET /support/categories` response (API.md section 12, public).
/// `PARTNER` is hidden in this customer app.
class SupportCategory {
  const SupportCategory({required this.value, required this.label});

  final String value;
  final String label;

  factory SupportCategory.fromJson(Map<String, dynamic> json) =>
      SupportCategory(
        value: json['value'] as String,
        label: json['label'] as String,
      );
}
