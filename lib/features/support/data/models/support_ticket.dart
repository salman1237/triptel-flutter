import 'support_message.dart';

/// `POST /support/tickets` / `GET /support/tickets` response (API.md
/// section 12) -- `order_id`/timestamps are only present on the full
/// `GET /support/tickets` shape FR-1101's list needs; FR-410's create
/// confirmation only reads id/reference/subject/category/status.
/// [messages] is only present on `GET /support/tickets/{id}` (and the
/// create/reply responses, which embed the same shape) -- null on the
/// plain list.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.reference,
    required this.subject,
    required this.category,
    required this.status,
    this.orderId,
    this.createdAt,
    this.lastMessageAt,
    this.resolvedAt,
    this.closedAt,
    this.messages,
  });

  final String id;
  final String reference;
  final String subject;
  final String category;
  final String status; // OPEN | ANSWERED | RESOLVED | CLOSED
  final String? orderId;
  final DateTime? createdAt;
  final DateTime? lastMessageAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final List<SupportMessage>? messages;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        reference: json['reference'] as String,
        subject: json['subject'] as String,
        category: json['category'] as String,
        status: json['status'] as String,
        orderId: json['order_id'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
        lastMessageAt: json['last_message_at'] == null
            ? null
            : DateTime.parse(json['last_message_at'] as String),
        resolvedAt: json['resolved_at'] == null
            ? null
            : DateTime.parse(json['resolved_at'] as String),
        closedAt: json['closed_at'] == null
            ? null
            : DateTime.parse(json['closed_at'] as String),
        messages: json['messages'] == null
            ? null
            : [
                for (final m in json['messages'] as List)
                  SupportMessage.fromJson(m as Map<String, dynamic>),
              ],
      );
}
