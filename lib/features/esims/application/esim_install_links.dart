import '../../../core/config/env.dart';

/// FR-404's "link to setup guide" -- the real web guide (FR-901's source,
/// `/guides/esim-setup-guide` per Functional_Requirements.md's routing
/// table) isn't ported into the app yet, so this links out to the existing
/// web page instead of a stub. Derived from [Env.apiBaseUrl] rather than a
/// second hardcoded host (Rules.md: beta API only, no hardcoded host) --
/// the frontend lives at the same host, one path segment up from `/api/v1`.
String setupGuideUrl() {
  final base = Env.apiBaseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
  return '$base/guides/esim-setup-guide';
}
