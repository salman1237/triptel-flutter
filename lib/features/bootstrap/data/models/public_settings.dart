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
  });

  final String platformName;
  final bool maintenanceMode;
  final String defaultCurrency;
  final String? supportPhone;
  final String? supportEmail;
  final String? supportWhatsapp;
  final String? logoLight;
  final String? googleClientId;

  factory PublicSettings.fromJson(Map<String, dynamic> json) => PublicSettings(
        platformName: json['platform_name'] as String? ?? 'Triptel',
        maintenanceMode: json['maintenance_mode'] as bool? ?? false,
        defaultCurrency: json['default_currency'] as String? ?? 'EUR',
        supportPhone: json['support_phone'] as String?,
        supportEmail: json['support_email'] as String?,
        supportWhatsapp: json['support_whatsapp'] as String?,
        logoLight: json['logo_light'] as String?,
        googleClientId: json['google_client_id'] as String?,
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
      };
}
