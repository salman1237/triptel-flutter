/// `GET /catalog/countries` row (API.md §3). Regional/multi-country packages
/// are pseudo-countries with `region == "Regional"` and `flag_url == null`
/// (globe icon fallback, FlagAvatar already handles that).
class Country {
  const Country({
    required this.id,
    required this.iso2,
    required this.nameEn,
    required this.isActive,
    required this.slug,
    this.iso3,
    this.nameBn,
    this.flagUrl,
    this.region,
    this.isPopular = false,
    this.popularOrder = 0,
  });

  final int id;
  final String iso2;
  final String? iso3;
  final String nameEn;
  final String? nameBn;
  final String? flagUrl;
  final String? region;
  final bool isPopular;
  final int popularOrder;
  final bool isActive;
  final String slug;

  bool get isRegional => region == 'Regional';

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json['id'] as int,
        iso2: json['iso2'] as String,
        iso3: json['iso3'] as String?,
        nameEn: json['name_en'] as String,
        nameBn: json['name_bn'] as String?,
        flagUrl: json['flag_url'] as String?,
        region: json['region'] as String?,
        isPopular: json['is_popular'] as bool? ?? false,
        popularOrder: json['popular_order'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        slug: json['slug'] as String,
      );
}
