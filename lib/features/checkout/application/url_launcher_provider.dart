import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Testability seam (same DI pattern as [shurjoPayLauncherProvider]) so
/// FR-310's 1-tap install button never needs the real `url_launcher`
/// platform channel under `flutter test`.
typedef UrlLauncher = Future<bool> Function(Uri url);

final urlLauncherProvider = Provider<UrlLauncher>(
  (ref) => (url) => url_launcher.launchUrl(url,
      mode: url_launcher.LaunchMode.externalApplication),
);
