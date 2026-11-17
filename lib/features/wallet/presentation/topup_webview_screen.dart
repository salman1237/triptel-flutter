import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../application/topup_callback.dart';

/// FR-603/FR-605: hosts ShurjoPay's wallet top-up `checkout_url` in an
/// in-app WebView (same "Gateway WebView" pattern as FR-307/FR-408's
/// flows). The terminal redirect is a real web URL (API.md §5) --
/// intercepted before it actually loads, popping with the parsed
/// [WalletTopupResult] (success/failed/cancelled + reason) instead of
/// letting the WebView navigate to the real web page. Any non-http(s)
/// scheme (bKash/Nagad app links) is launched externally.
class WalletTopupWebViewScreen extends StatefulWidget {
  const WalletTopupWebViewScreen({super.key, required this.checkoutUrl});

  final String checkoutUrl;

  @override
  State<WalletTopupWebViewScreen> createState() =>
      _WalletTopupWebViewScreenState();
}

class _WalletTopupWebViewScreenState extends State<WalletTopupWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
          NavigationDelegate(onNavigationRequest: _onNavigationRequest))
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;

    if (isWalletTopupCallbackUrl(uri)) {
      Navigator.of(context).pop(parseWalletTopupCallback(uri));
      return NavigationDecision.prevent;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      launchUrl(uri, mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('wallet-topup-shurjopay-close-button'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('ShurjoPay'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
