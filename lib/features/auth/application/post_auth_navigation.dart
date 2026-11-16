import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/checkout/pending_purchase_provider.dart';
import '../../catalog/application/catalog_providers.dart';
import '../../checkout/presentation/checkout_review_screen.dart';
import 'auth_state.dart';

/// FR-106: after a real sign-in (login/register/Google), land on
/// [postAuthRoute] as usual -- unless a guest was sent here mid-purchase
/// (a pending purchase is on file), in which case resume checkout instead
/// of landing on Home. Only overrides the '/home' case: Set Password /
/// Suspended still take priority over resuming a purchase, same as
/// FR-105b's own gating.
Future<void> navigateAfterAuth(
  BuildContext context,
  WidgetRef ref,
  AuthState state,
) async {
  final route = postAuthRoute(state);
  if (route == '/home') {
    final pending = await ref.read(pendingPurchaseProvider.future);
    if (pending != null) {
      await ref.read(pendingPurchaseProvider.notifier).clear();
      try {
        final product =
            await ref.read(catalogApiProvider).getProduct(pending.productId);
        if (context.mounted) {
          context.go('/checkout/review',
              extra: CheckoutReviewArgs(
                product: product,
                countryName: pending.countryName,
                initialDiscountCode: pending.discountCode,
              ));
        }
        return;
      } catch (_) {
        // The product may have gone inactive/been removed since -- fall
        // through to Home rather than leaving the user stuck.
      }
    }
  }
  if (context.mounted) context.go(route);
}
