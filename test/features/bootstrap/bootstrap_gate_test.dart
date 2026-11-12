import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/bootstrap/presentation/bootstrap_gate.dart';
import 'package:triptel/features/bootstrap/presentation/maintenance_screen.dart';
import 'package:triptel/features/bootstrap/presentation/splash_screen.dart';

const _child = Text('home-content', key: ValueKey('home-content'));

BootstrapData _data({required bool maintenance}) => BootstrapData(
      settings: PublicSettings(
        platformName: 'Triptel',
        maintenanceMode: maintenance,
        defaultCurrency: 'EUR',
        supportEmail: maintenance ? 'support@triptel.co' : null,
      ),
      rates: const [],
      languages: const [],
      fromCache: false,
    );

Future<void> _pumpGate(
    WidgetTester tester, AsyncValue<BootstrapData> state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bootstrapProvider.overrideWith((ref) => state.when(
              data: (d) => Future.value(d),
              loading: () => Completer<BootstrapData>().future,
              error: (e, st) => Future<BootstrapData>.error(e, st),
            ))
      ],
      child: const MaterialApp(home: BootstrapGate(child: _child)),
    ),
  );
}

void main() {
  testWidgets('shows SplashScreen while bootstrap is loading', (tester) async {
    await _pumpGate(tester, const AsyncValue.loading());
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('home-content')), findsNothing);
  });

  testWidgets('shows MaintenanceScreen when maintenance_mode is true',
      (tester) async {
    await _pumpGate(tester, AsyncValue.data(_data(maintenance: true)));
    await tester.pump();
    await tester.pump();
    expect(find.byType(MaintenanceScreen), findsOneWidget);
    expect(find.text('support@triptel.co'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-content')), findsNothing);
  });

  testWidgets('shows the child when maintenance_mode is false', (tester) async {
    await _pumpGate(tester, AsyncValue.data(_data(maintenance: false)));
    await tester.pump();
    await tester.pump();
    expect(find.byType(MaintenanceScreen), findsNothing);
    expect(find.byKey(const ValueKey('home-content')), findsOneWidget);
  });
}
