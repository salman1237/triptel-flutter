import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../application/shurjopay_callback.dart';

/// FR-307: hosts ShurjoPay's `checkout_url` in an in-app WebView
/// (Architecture.md's "Gateway WebView" flow). Intercepts the terminal
/// `triptel://payment-callback` redirect (API.md §9) and pops with the
/// parsed [ShurjoPayCallback] instead of letting the WebView navigate
/// there (the scheme has no http(s) handler to load). Any `intent://`
/// scheme (bKash/Nagad app links) is launched externally rather than
/// loaded in the WebView.
class ShurjoPayWebViewScreen extends StatefulWidget {
  const ShurjoPayWebViewScreen({super.key, required this.checkoutUrl});

  final String checkoutUrl;

  @override
  State<ShurjoPayWebViewScreen> createState() => _ShurjoPayWebViewScreenState();
}

class _ShurjoPayWebViewScreenState extends State<ShurjoPayWebViewScreen> {
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

    if (isShurjoPayCallbackUrl(uri)) {
      Navigator.of(context).pop(parseShurjoPayCallback(uri));
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
          key: const ValueKey('shurjopay-close-button'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('ShurjoPay'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
