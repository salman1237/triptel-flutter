import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/deeplink/deep_link_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pendingReferralProvider starts null when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(pendingReferralProvider.future), isNull);
  });

  test('save() persists the referral code across a fresh container', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(pendingReferralProvider.future);
    await container.read(pendingReferralProvider.notifier).save('ABC123');
    expect(container.read(pendingReferralProvider).value, 'ABC123');

    final relaunched = ProviderContainer();
    addTearDown(relaunched.dispose);
    expect(await relaunched.read(pendingReferralProvider.future), 'ABC123');
  });

  test(
      'pendingPaymentCallbackProvider and pendingTrackingTokenProvider start null',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(pendingPaymentCallbackProvider), isNull);
    expect(container.read(pendingTrackingTokenProvider), isNull);
    expect(container.read(lastUnknownDeepLinkProvider), isNull);
  });
}
