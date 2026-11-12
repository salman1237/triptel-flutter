import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/deeplink/deep_link_listener.dart';
import '../core/deeplink/deep_link_providers.dart';
import 'router.dart';

/// Activates FR-007's deep-link listener for the app's lifetime and
/// navigates to `/track/:token` whenever a tracking link comes in.
class DeepLinkBridge extends ConsumerWidget {
  const DeepLinkBridge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(deepLinkListenerProvider);
    ref.listen(pendingTrackingTokenProvider, (previous, token) {
      if (token == null) return;
      appRouter.go('/track/$token');
      ref.read(pendingTrackingTokenProvider.notifier).state = null;
    });
    return child;
  }
}
