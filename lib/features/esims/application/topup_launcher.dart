import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/topup_webview_screen.dart';

/// Opens FR-408's in-app WebView and resolves with whether the top-up
/// failed (`true`), succeeded (`false`), or the user backed out first
/// (`null`) -- a provider seam, same pattern as checkout's
/// `shurjoPayLauncherProvider`, since `webview_flutter` can't render in a
/// plain widget test.
typedef TopupLauncher = Future<bool?> Function(
    BuildContext context, String checkoutUrl, String esimId);

final topupLauncherProvider = Provider<TopupLauncher>(
  (ref) => (context, checkoutUrl, esimId) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              TopupWebViewScreen(checkoutUrl: checkoutUrl, esimId: esimId),
        ),
      ),
);
