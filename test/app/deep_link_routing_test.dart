import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/deeplink/deep_link_providers.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/tracking/presentation/tracking_screen.dart';
import 'package:triptel/main.dart';

void main() {
  testWidgets('FR-007: a pending tracking token navigates to TrackingScreen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWith(
          (ref) async => const BootstrapData(
            settings: PublicSettings(
              platformName: 'Triptel',
              maintenanceMode: false,
              defaultCurrency: 'EUR',
            ),
            rates: [],
            languages: [],
            fromCache: false,
          ),
        ),
        popularCountriesProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
          container: container, child: const TriptelApp()),
    );
    await tester.pumpAndSettle();

    container.read(pendingTrackingTokenProvider.notifier).state = 'TOK999';
    await tester.pumpAndSettle();

    expect(find.byType(TrackingScreen), findsOneWidget);
    expect(find.textContaining('TOK999'), findsOneWidget);
    // Consumed, so a second identical link can still trigger navigation later.
    expect(container.read(pendingTrackingTokenProvider), isNull);
  });
}
