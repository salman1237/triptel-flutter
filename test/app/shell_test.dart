import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/app/app_shell.dart';
import 'package:triptel/features/account/presentation/account_screen.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/presentation/home_screen.dart';
import 'package:triptel/features/esims/presentation/my_esims_screen.dart';
import 'package:triptel/features/wallet/presentation/wallet_screen.dart';
import 'package:triptel/main.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
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
      child: const TriptelApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('FR-004: the 4-tab shell starts on Home and switches tabs',
      (tester) async {
    await _pumpApp(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Home')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-My eSIMs')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Wallet')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Account')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-My eSIMs')));
    await tester.pumpAndSettle();
    expect(find.byType(MyEsimsScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-Wallet')));
    await tester.pumpAndSettle();
    expect(find.byType(WalletScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-Account')));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-Home')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
