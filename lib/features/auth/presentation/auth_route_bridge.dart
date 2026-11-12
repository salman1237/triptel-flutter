import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/router.dart';
import '../application/auth_providers.dart';
import '../application/auth_state.dart';

/// FR-109: whenever the session state becomes [AuthSuspended] — on login,
/// Google sign-in, or while restoring a session on launch (FR-107) — routes
/// to the dedicated suspended screen, from wherever the app currently is.
class AuthRouteBridge extends ConsumerWidget {
  const AuthRouteBridge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.value is AuthSuspended && previous?.value is! AuthSuspended) {
        appRouter.go('/suspended');
      }
    });
    return child;
  }
}
