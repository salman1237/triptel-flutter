/// `POST /support/tickets` response (API.md section 12) -- only the fields
/// FR-410's confirmation needs; `GET /support/tickets` returns the same
/// shape for the future ticket list (FR-1101, not built yet).
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.reference,
    required this.subject,
    required this.category,
    required this.status,
  });

  final String id;
  final String reference;
  final String subject;
  final String category;
  final String status;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        reference: json['reference'] as String,
        subject: json['subject'] as String,
        category: json['category'] as String,
        status: json['status'] as String,
      );
}
