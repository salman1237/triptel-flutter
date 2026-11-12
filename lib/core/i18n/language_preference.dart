import '../../features/bootstrap/data/models/language.dart';

/// FR-006's pure selection rule (Architecture.md: business rules in plain
/// Dart). A stored choice wins only if the backend still lists it as active;
/// otherwise fall back to English.
String resolveInitialLanguage({
  required String? storedCode,
  required List<Language> available,
}) {
  final activeCodes = available.where((l) => l.isActive).map((l) => l.code);
  if (storedCode != null && activeCodes.contains(storedCode)) return storedCode;
  return activeCodes.contains('en')
      ? 'en'
      : (activeCodes.isEmpty ? 'en' : activeCodes.first);
}

/// Whether [languageCode] should render right-to-left, per its `is_rtl` flag
/// (API.md §1). Defaults to false for an unknown code rather than guessing.
bool isRtlLanguage(String languageCode, List<Language> available) {
  final match = available.where((l) => l.code == languageCode);
  return match.isEmpty ? false : match.first.isRtl;
}

/// Looks up `namespaces[ns][key]`, falling back to [fallback] when the
/// namespace/key is missing (the server only back-fills English server-side
/// for languages it knows about, not for a payload the client never fetched).
String translate(
  Map<String, dynamic> namespaces, {
  required String ns,
  required String key,
  required String fallback,
}) {
  final namespace = namespaces[ns];
  if (namespace is! Map) return fallback;
  final value = namespace[key];
  return value is String ? value : fallback;
}
