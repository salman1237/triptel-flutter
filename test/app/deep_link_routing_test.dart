import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/deeplink/deep_link_providers.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';
import 'package:triptel/features/tracking/application/tracking_providers.dart';
import 'package:triptel/features/tracking/data/tracking_api.dart';
import 'package:triptel/features/tracking/presentation/tracking_screen.dart';
import 'package:triptel/main.dart';

class _FakeTrackingApi implements TrackingApi {
  @override
  Future<EsimStatus> getPublicStatus(String token) async =>
      throw Exception('not used by this routing test');
}

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
        trackingApiProvider.overrideWithValue(_FakeTrackingApi()),
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
    expect(tester.widget<TrackingScreen>(find.byType(TrackingScreen)).token,
        'TOK999');
    // Consumed, so a second identical link can still trigger navigation later.
    expect(container.read(pendingTrackingTokenProvider), isNull);
  });
}
