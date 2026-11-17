/// `GET /kyc/me` response (API.md §11). `status` is null until a
/// submission exists.
class KycStatus {
  const KycStatus({
    required this.submitted,
    this.status,
    this.rejectionReason,
    this.submittedAt,
  });

  final bool submitted;
  final String? status; // PENDING | APPROVED | REJECTED
  final String? rejectionReason;
  final DateTime? submittedAt;

  factory KycStatus.fromJson(Map<String, dynamic> json) => KycStatus(
        submitted: json['submitted'] as bool,
        status: json['status'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
        submittedAt: json['submitted_at'] == null
            ? null
            : DateTime.parse(json['submitted_at'] as String),
      );
}
