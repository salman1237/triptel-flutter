import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'language_providers.dart';

/// FR-006/FR-006b: wraps the app -- including `BootstrapGate`'s
/// splash/maintenance/error branches, since this sits outside it in
/// `main.dart` -- in the right [TextDirection] for the selected language
/// (RTL for Arabic). Defaults to LTR while loading/on error rather than
/// flashing a direction change later; splash and a true network error (no
/// cached bootstrap data at all) have no way to know the backend's `is_rtl`
/// flag for the saved language yet, so they stay LTR until bootstrap data
/// (even cached/`fromCache`) resolves -- maintenance mode, which always has
/// real bootstrap data, renders RTL correctly.
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
