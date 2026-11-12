import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/shared_prefs_provider.dart';
import 'deep_link.dart';

const _referralPrefsKey = 'referral.pendingCode';

/// A referral code seen on an incoming link, persisted until FR-803 (claim
/// referrer) or FR-101 (register, pre-filled) consumes it.
class PendingReferralNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getString(_referralPrefsKey);
  }

  Future<void> save(String code) async {
    state = AsyncData(code);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_referralPrefsKey, code);
  }
}

final pendingReferralProvider =
    AsyncNotifierProvider<PendingReferralNotifier, String?>(
  PendingReferralNotifier.new,
);

/// The most recent `triptel://payment-callback` params, held until checkout
/// (FR-306/FR-307, not yet built) re-reads server state and consumes it.
final pendingPaymentCallbackProvider =
    StateProvider<PaymentCallbackDeepLink?>((ref) => null);

/// The most recent tracking token seen, for the router to navigate to
/// (`/track/:token`, FR-501's placeholder for now).
final pendingTrackingTokenProvider = StateProvider<String?>((ref) => null);

/// The most recent link this app couldn't route anywhere (still logged so a
/// future feature can widen `parseDeepLink`'s matches).
final lastUnknownDeepLinkProvider = StateProvider<Uri?>((ref) => null);
