/// `GET /esims/{esim_id}/status` response (API.md section 7). Cached 5 min
/// server-side; never fails because the supplier is down (returns the last
/// snapshot + `telemetry.error` instead). Use `usage.allowance_mb` and
/// `validity.days` for real totals (they include top-ups) -- `product.*` is
/// only the original plan (Rules.md).
class EsimStatus {
  const EsimStatus({
    required this.esimId,
    required this.orderNo,
    required this.product,
    required this.iccid,
    required this.lpaString,
    required this.qrCodeData,
    required this.smdpAddress,
    required this.matchingId,
    required this.esimStatus,
    required this.status,
    required this.usage,
    required this.validity,
    required this.shareUrl,
    required this.telemetry,
  });

  final String esimId;
  final String orderNo;
  final EsimStatusProduct product;
  final String iccid;
  final String lpaString;
  final String qrCodeData;
  final String smdpAddress;
  final String? matchingId;

  /// ALLOCATED|RELEASED|INSTALLED|ACTIVE|EXPIRED|SUSPENDED|REVOKED|CANCELLED
  /// -- drives actions (FR-405): SUSPENDED/REVOKED/CANCELLED/EXPIRED hide
  /// install and top-up and show a lifecycle banner instead.
  final String esimStatus;
  final EsimStatusInfo status;
  final EsimUsageInfo usage;
  final EsimValidityInfo validity;

  /// Web tracking page; null on the public (unauthenticated) variant of
  /// this response.
  final String? shareUrl;
  final EsimTelemetryInfo telemetry;

  factory EsimStatus.fromJson(Map<String, dynamic> json) => EsimStatus(
        esimId: json['esim_id'] as String,
        orderNo: json['order_no'] as String? ?? '',
        product: EsimStatusProduct.fromJson(
            json['product'] as Map<String, dynamic>? ?? const {}),
        iccid: json['iccid'] as String? ?? '',
        lpaString: json['lpa_string'] as String? ?? '',
        qrCodeData: json['qr_code_data'] as String? ?? '',
        smdpAddress: json['smdp_address'] as String? ?? '',
        matchingId: json['matching_id'] as String?,
        esimStatus: json['esim_status'] as String? ?? '',
        status: EsimStatusInfo.fromJson(
            json['status'] as Map<String, dynamic>? ?? const {}),
        usage: EsimUsageInfo.fromJson(
            json['usage'] as Map<String, dynamic>? ?? const {}),
        validity: EsimValidityInfo.fromJson(
            json['validity'] as Map<String, dynamic>? ?? const {}),
        shareUrl: json['share_url'] as String?,
        telemetry: EsimTelemetryInfo.fromJson(
            json['telemetry'] as Map<String, dynamic>? ?? const {}),
      );
}

class EsimStatusProduct {
  const EsimStatusProduct({
    required this.title,
    required this.validityDays,
    required this.isUnlimited,
    required this.dataAmountGb,
  });

  final String title;
  final int validityDays;
  final bool isUnlimited;
  final double dataAmountGb;

  factory EsimStatusProduct.fromJson(Map<String, dynamic> json) =>
      EsimStatusProduct(
        title: json['title'] as String? ?? '',
        validityDays: json['validity_days'] as int? ?? 0,
        isUnlimited: json['is_unlimited'] as bool? ?? false,
        dataAmountGb:
            double.tryParse(json['data_amount_gb']?.toString() ?? '') ?? 0,
      );
}

/// `device_model` is only ever supplied by the VivaPe supplier -- eSIM
/// Access always returns null here (API.md).
class EsimStatusInfo {
  const EsimStatusInfo({
    required this.label,
    required this.code,
    required this.isInstalled,
    required this.isActivated,
    required this.deviceModel,
  });

  final String label;
  final int code;
  final bool isInstalled;
  final bool isActivated;
  final String? deviceModel;

  factory EsimStatusInfo.fromJson(Map<String, dynamic> json) => EsimStatusInfo(
        label: json['label'] as String? ?? '',
        code: json['code'] as int? ?? 0,
        isInstalled: json['is_installed'] as bool? ?? false,
        isActivated: json['is_activated'] as bool? ?? false,
        deviceModel: json['device_model'] as String?,
      );
}

/// Unlimited: `allowanceMb`/`remainingMb`/`usedPct` are all null -- no
/// progress bar (Rules.md).
class EsimUsageInfo {
  const EsimUsageInfo({
    required this.usedFormatted,
    required this.allowanceMb,
    required this.remainingMb,
    required this.remainingFormatted,
    required this.usedPct,
    required this.isUnlimited,
  });

  final String usedFormatted;
  final double? allowanceMb;
  final double? remainingMb;
  final String remainingFormatted;
  final double? usedPct;
  final bool isUnlimited;

  factory EsimUsageInfo.fromJson(Map<String, dynamic> json) => EsimUsageInfo(
        usedFormatted: json['formatted'] as String? ?? '',
        allowanceMb: json['is_unlimited'] == true
            ? null
            : double.tryParse(json['allowance_mb']?.toString() ?? ''),
        remainingMb: json['is_unlimited'] == true
            ? null
            : double.tryParse(json['remaining_mb']?.toString() ?? ''),
        remainingFormatted: json['remaining_formatted'] as String? ?? '',
        usedPct: json['is_unlimited'] == true
            ? null
            : (json['used_pct'] as num?)?.toDouble(),
        isUnlimited: json['is_unlimited'] as bool? ?? false,
      );
}

/// `activatedAt`/`expiresAt` stay null until installed (API.md, Rules.md):
/// "say 'Validity starts on install'".
class EsimValidityInfo {
  const EsimValidityInfo({
    required this.days,
    required this.activatedAt,
    required this.expiresAt,
    required this.note,
  });

  final int days;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final String note;

  factory EsimValidityInfo.fromJson(Map<String, dynamic> json) =>
      EsimValidityInfo(
        days: json['days'] as int? ?? 0,
        activatedAt: json['activated_at'] != null
            ? DateTime.parse(json['activated_at'] as String)
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        note: json['note'] as String? ?? '',
      );
}

/// `error` non-null -> show "Live usage temporarily unavailable" +
/// `fetchedAt` (API.md) -- never treated as a hard failure, since the
/// server always returns the last good snapshot alongside it.
class EsimTelemetryInfo {
  const EsimTelemetryInfo({
    required this.fetchedAt,
    required this.error,
    required this.available,
  });

  final DateTime? fetchedAt;
  final String? error;
  final bool available;

  factory EsimTelemetryInfo.fromJson(Map<String, dynamic> json) =>
      EsimTelemetryInfo(
        fetchedAt: json['fetched_at'] != null
            ? DateTime.tryParse(json['fetched_at'] as String)
            : null,
        error: json['error'] as String?,
        available: json['available'] as bool? ?? true,
      );
}
