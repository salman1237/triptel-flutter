import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Testability seam (same DI pattern as `shurjoPayLauncherProvider`) so a
/// 1-tap install button never needs the real `url_launcher` platform
/// channel under `flutter test`. Shared between checkout (FR-310) and the
/// My eSIMs detail screen (FR-404).
typedef UrlLauncher = Future<bool> Function(Uri url);

final urlLauncherProvider = Provider<UrlLauncher>(
  (ref) => (url) => url_launcher.launchUrl(url,
      mode: url_launcher.LaunchMode.externalApplication),
);
