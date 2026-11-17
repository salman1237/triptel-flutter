import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'topup_callback.dart';
import '../presentation/topup_webview_screen.dart';

/// Opens FR-603's in-app WebView and resolves with the parsed
/// [WalletTopupResult] (FR-605: success/failed/cancelled + reason), or
/// `null` if the user backed out before any terminal redirect -- a
/// provider seam, same pattern as checkout's `shurjoPayLauncherProvider`
/// and the eSIM data top-up's `topupLauncherProvider`, since
/// `webview_flutter` can't render in a plain widget test.
typedef WalletTopupLauncher = Future<WalletTopupResult?> Function(
    BuildContext context, String checkoutUrl);

final walletTopupLauncherProvider = Provider<WalletTopupLauncher>(
  (ref) => (context, checkoutUrl) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WalletTopupWebViewScreen(checkoutUrl: checkoutUrl),
        ),
      ),
);
