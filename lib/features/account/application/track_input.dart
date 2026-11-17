import '../../../core/deeplink/deep_link.dart';

/// FR-1001's "Track an eSIM" row: accepts either a full tracking link
/// (`https://triptel.co/track/<token>`) or a bare token, reusing FR-007's
/// deep-link parser so both forms resolve the same way. Returns null for
/// empty input.
String? resolveTrackingToken(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    final parsed = parseDeepLink(uri);
    if (parsed is TrackingDeepLink) return parsed.token;
  }
  return trimmed;
}
