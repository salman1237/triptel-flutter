import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/shurjopay_webview_screen.dart';
import 'shurjopay_callback.dart';

/// Opens FR-307's in-app WebView and resolves with its terminal callback
/// (or null if the user backed out first). A provider seam -- widget tests
/// override this instead of driving a real platform WebView, which
/// `webview_flutter` can't render in a plain widget test.
typedef ShurjoPayLauncher = Future<ShurjoPayCallback?> Function(
    BuildContext context, String checkoutUrl);

final shurjoPayLauncherProvider = Provider<ShurjoPayLauncher>(
  (ref) => (context, checkoutUrl) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShurjoPayWebViewScreen(checkoutUrl: checkoutUrl),
        ),
      ),
);
