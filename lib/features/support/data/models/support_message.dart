import 'support_attachment.dart';

/// A message in `GET /support/tickets/{id}`'s `messages[]` (API.md section
/// 12): `author` is already the display string ("You"/"Support"), no
/// client-side guessing needed.
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.body,
    required this.isStaff,
    required this.author,
    required this.createdAt,
    required this.attachments,
  });

  final String id;
  final String body;
  final bool isStaff;
  final String author;
  final DateTime createdAt;
  final List<SupportAttachment> attachments;

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: json['id'] as String,
        body: json['body'] as String,
        isStaff: json['is_staff'] as bool,
        author: json['author'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        attachments: [
          for (final a in (json['attachments'] as List? ?? const []))
            SupportAttachment.fromJson(a as Map<String, dynamic>),
        ],
      );
}
