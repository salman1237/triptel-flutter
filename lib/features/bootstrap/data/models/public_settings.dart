import '../../../../core/money/money.dart';

/// `GET /settings/public` response (API.md §1). Any contact field may be null
/// — hide that contact row, never invent one.
class PublicSettings {
  const PublicSettings({
    required this.platformName,
    required this.maintenanceMode,
    required this.defaultCurrency,
    this.supportPhone,
    this.supportEmail,
    this.supportWhatsapp,
    this.logoLight,
    this.googleClientId,
    this.topupMin = const Money(1),
    this.topupMax = const Money(200000),
  });

  final String platformName;
  final bool maintenanceMode;
  final String defaultCurrency;
  final String? supportPhone;
  final String? supportEmail;
  final String? supportWhatsapp;
  final String? logoLight;
  final String? googleClientId;

  /// `topup_min`/`topup_max` (API.md §1): wallet top-up limits, EUR.
  final Money topupMin;
  final Money topupMax;

  factory PublicSettings.fromJson(Map<String, dynamic> json) => PublicSettings(
        platformName: json['platform_name'] as String? ?? 'Triptel',
        maintenanceMode: json['maintenance_mode'] as bool? ?? false,
        defaultCurrency: json['default_currency'] as String? ?? 'EUR',
        supportPhone: json['support_phone'] as String?,
        supportEmail: json['support_email'] as String?,
        supportWhatsapp: json['support_whatsapp'] as String?,
        logoLight: json['logo_light'] as String?,
        googleClientId: json['google_client_id'] as String?,
        topupMin: json['topup_min'] != null
            ? Money.parseEur(json['topup_min'] as String)
            : const Money(1),
        topupMax: json['topup_max'] != null
            ? Money.parseEur(json['topup_max'] as String)
            : const Money(200000),
      );

  Map<String, dynamic> toJson() => {
        'platform_name': platformName,
        'maintenance_mode': maintenanceMode,
        'default_currency': defaultCurrency,
        'support_phone': supportPhone,
        'support_email': supportEmail,
        'support_whatsapp': supportWhatsapp,
        'logo_light': logoLight,
        'google_client_id': googleClientId,
        'topup_min': (topupMin.eurCents / 100).toStringAsFixed(2),
        'topup_max': (topupMax.eurCents / 100).toStringAsFixed(2),
      };
}
