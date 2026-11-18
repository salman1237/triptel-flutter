/// `GET /settings/legal` row (API.md section 1-adjacent, documented near
/// `GET /settings/legal/{slug}`): list item, no `body` yet.
class LegalDocument {
  const LegalDocument({
    required this.slug,
    required this.title,
    required this.updatedAt,
  });

  final String slug;
  final String title;
  final DateTime? updatedAt;

  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
        slug: json['slug'] as String,
        title: json['title'] as String,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
}

/// `GET /settings/legal/{slug}` response -- the list row plus the real
/// `body`, admin-edited markdown-lite.
class LegalDocumentDetail {
  const LegalDocumentDetail({
    required this.slug,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  final String slug;
  final String title;
  final String body;
  final DateTime? updatedAt;

  factory LegalDocumentDetail.fromJson(Map<String, dynamic> json) =>
      LegalDocumentDetail(
        slug: json['slug'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
}
