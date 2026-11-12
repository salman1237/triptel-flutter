import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'deep_link.dart';
import 'deep_link_dispatcher.dart';
import 'deep_link_providers.dart';

/// Subscribes to `app_links` once per app run and routes every incoming URI
/// through [handleDeepLink], writing into the thin state providers that
/// own features (checkout, tracking, referrals) will read from. The plugin
/// wiring itself is deliberately thin/untested glue; [handleDeepLink] and
/// [parseDeepLink] carry the real logic and are unit-tested directly.
final deepLinkListenerProvider = Provider<void>((ref) {
  final appLinks = AppLinks();
  StreamSubscription<Uri>? subscription;

  Future<void> handle(Uri uri) async {
    handleDeepLink(
      uri,
      onPaymentCallback: (params) => ref
          .read(pendingPaymentCallbackProvider.notifier)
          .state = PaymentCallbackDeepLink(params),
      onTracking: (token) =>
          ref.read(pendingTrackingTokenProvider.notifier).state = token,
      onUnknown: (unknownUri) =>
          ref.read(lastUnknownDeepLinkProvider.notifier).state = unknownUri,
      onReferral: (code) =>
          ref.read(pendingReferralProvider.notifier).save(code),
    );
  }

  appLinks.getInitialLink().then((uri) {
    if (uri != null) handle(uri);
  });
  subscription = appLinks.uriLinkStream.listen(handle);

  ref.onDispose(() => subscription?.cancel());
});
