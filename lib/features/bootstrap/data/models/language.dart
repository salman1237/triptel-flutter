/// `GET /settings/languages` entry (API.md §1).
class Language {
  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.isActive,
    required this.isRtl,
    this.flagEmoji,
  });

  final String code;
  final String name;
  final String nativeName;
  final bool isActive;
  final bool isRtl;
  final String? flagEmoji;

  factory Language.fromJson(Map<String, dynamic> json) => Language(
        code: json['code'] as String,
        name: json['name'] as String,
        nativeName: json['native_name'] as String? ?? json['name'] as String,
        isActive: json['is_active'] as bool? ?? true,
        isRtl: json['is_rtl'] as bool? ?? false,
        flagEmoji: json['flag_emoji'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'native_name': nativeName,
        'is_active': isActive,
        'is_rtl': isRtl,
        'flag_emoji': flagEmoji,
      };
}
