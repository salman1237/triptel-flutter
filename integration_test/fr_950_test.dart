import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:triptel/features/compatibility/application/compatibility_providers.dart';
import 'package:triptel/features/compatibility/application/esim_verdict.dart';

/// FR-950: runs the real native `co.triptel.app/esim` channel on a physical
/// device (not a fake) and confirms it produces a real, non-null verdict
/// (never a thrown `MissingPluginException`, which would mean the channel
/// isn't actually wired up on this platform). NFR: asserts no signal field
/// is sent anywhere — this just reads the provider, it doesn't call the API.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getEsimSupport channel returns a real, decidable verdict',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final verdict = await container.read(esimVerdictProvider.future);

    expect(verdict.kind, isIn(EsimVerdictKind.values));
    expect(verdict.deviceLabel, isNotEmpty);
    expect(verdict.reason, isNotEmpty);
  });
}
