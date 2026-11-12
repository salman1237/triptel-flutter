import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'language_providers.dart';

/// FR-006: wraps the app in the right [TextDirection] for the selected
/// language (RTL for Arabic). Defaults to LTR while loading/on error rather
/// than flashing a direction change later.
///
/// Known limitation: this only wraps `BootstrapGate`'s `child` (the normal
/// app content), not its splash/maintenance/error branches, which always
/// render LTR even if the user already has an RTL language saved. Rare in
/// practice (maintenance mode is uncommon) — tracked as FR-006b rather than
/// fixed inline.
class RtlScope extends ConsumerWidget {
  const RtlScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRtl = ref
        .watch(isRtlProvider)
        .maybeWhen(data: (value) => value, orElse: () => false);
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: child,
    );
  }
}
