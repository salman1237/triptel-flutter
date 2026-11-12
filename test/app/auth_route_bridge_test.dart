import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/application/auth_state.dart';
import 'package:triptel/features/auth/presentation/suspended_screen.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/main.dart';

class _ControllableAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthUnauthenticated();
}

void main() {
  testWidgets(
      'FR-109: becoming suspended while already past the login screen '
      'still navigates to /suspended (AuthRouteBridge)', (tester) async {
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
        authNotifierProvider.overrideWith(_ControllableAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
          container: container, child: const TriptelApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SuspendedScreen), findsNothing);

    container.read(authNotifierProvider.notifier).state =
        const AsyncData(AuthSuspended());
    await tester.pumpAndSettle();

    expect(find.byType(SuspendedScreen), findsOneWidget);
  });
}
