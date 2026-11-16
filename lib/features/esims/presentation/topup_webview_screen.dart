import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../application/topup_callback.dart';

/// FR-408: hosts ShurjoPay's top-up `checkout_url` in an in-app WebView
/// (same "Gateway WebView" pattern as FR-307's checkout flow). Unlike
/// checkout's custom-scheme redirect, the top-up flow's terminal redirect
/// is a real web URL (API.md section 7) -- intercepted before it actually
/// loads, popping with `true` (failed) / `false` (success) instead of
/// letting the WebView navigate to the real web page. Any non-http(s)
/// scheme (bKash/Nagad app links) is launched externally.
class TopupWebViewScreen extends StatefulWidget {
  const TopupWebViewScreen(
      {super.key, required this.checkoutUrl, required this.esimId});

  final String checkoutUrl;
  final String esimId;

  @override
  State<TopupWebViewScreen> createState() => _TopupWebViewScreenState();
}

class _TopupWebViewScreenState extends State<TopupWebViewScreen> {
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

    if (isTopupCallbackUrl(uri, widget.esimId)) {
      Navigator.of(context).pop(topupCallbackFailed(uri));
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
          key: const ValueKey('topup-shurjopay-close-button'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('ShurjoPay'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
