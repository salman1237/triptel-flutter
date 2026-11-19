import 'shared_order.dart';
import 'shared_product.dart';
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
    this.authorAvatarUrl,
    this.messageType = 'TEXT',
    this.sharedOrder,
    this.sharedProduct,
  });

  final String id;
  final String body;
  final bool isStaff;
  final String author;
  final DateTime createdAt;
  final List<SupportAttachment> attachments;

  /// `null` for messages sent before the real-time chat feature shipped
  /// (API.md section 12) or when the author has no avatar set.
  final String? authorAvatarUrl;

  /// `TEXT`|`ORDER_SHARE`|`PRODUCT_SHARE` (API.md section 12) -- always
  /// explicit, never inferred from whether [sharedOrder]/[sharedProduct]
  /// is non-null (e.g. a deleted shared order leaves this as
  /// `ORDER_SHARE` with a null [sharedOrder] -- still a share message,
  /// just with nothing left to link to).
  final String messageType;
  final SharedOrder? sharedOrder;
  final SharedProduct? sharedProduct;

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
        authorAvatarUrl: json['author_avatar_url'] as String?,
        messageType: json['message_type'] as String? ?? 'TEXT',
        sharedOrder: json['shared_order'] == null
            ? null
            : SharedOrder.fromJson(
                json['shared_order'] as Map<String, dynamic>),
        sharedProduct: json['shared_product'] == null
            ? null
            : SharedProduct.fromJson(
                json['shared_product'] as Map<String, dynamic>),
      );
}
