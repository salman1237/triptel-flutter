/// A message attachment in `GET /support/tickets/{id}`'s `messages[].
/// attachments[]` (API.md section 12). Download requires auth, via
/// `GET /support/attachments/{id}` -- [url] is that path.
class SupportAttachment {
  const SupportAttachment({
    required this.id,
    required this.name,
    required this.contentType,
    required this.sizeBytes,
    required this.url,
  });

  final String id;
  final String name;
  final String contentType;
  final int sizeBytes;
  final String url;

  bool get isImage => contentType.startsWith('image/');

  factory SupportAttachment.fromJson(Map<String, dynamic> json) =>
      SupportAttachment(
        id: json['id'] as String,
        name: json['name'] as String,
        contentType: json['content_type'] as String,
        sizeBytes: json['size_bytes'] as int,
        url: json['url'] as String,
      );
}
