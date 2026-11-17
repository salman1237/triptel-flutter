import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/topup_webview_screen.dart';

/// Opens FR-603's in-app WebView and resolves with whether the top-up
/// failed/was cancelled (`true`), succeeded (`false`), or the user backed
/// out first (`null`) -- a provider seam, same pattern as checkout's
/// `shurjoPayLauncherProvider` and the eSIM data top-up's
/// `topupLauncherProvider`, since `webview_flutter` can't render in a plain
/// widget test.
typedef WalletTopupLauncher = Future<bool?> Function(
    BuildContext context, String checkoutUrl);

final walletTopupLauncherProvider = Provider<WalletTopupLauncher>(
  (ref) => (context, checkoutUrl) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WalletTopupWebViewScreen(checkoutUrl: checkoutUrl),
        ),
      ),
);
