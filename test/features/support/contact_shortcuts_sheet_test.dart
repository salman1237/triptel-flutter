import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/install/url_launcher_provider.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/support/presentation/contact_shortcuts_sheet.dart';

BootstrapData _bootstrap({
  String? whatsapp = '+8801979891996',
  String? phone = '+8801979891996',
  String? email = 'support@triptel.co',
}) =>
    BootstrapData(
      settings: PublicSettings(
        platformName: 'Triptel',
        maintenanceMode: false,
        defaultCurrency: 'EUR',
        supportWhatsapp: whatsapp,
        supportPhone: phone,
        supportEmail: email,
      ),
      rates: const [],
      languages: const [],
      fromCache: false,
    );

Widget _app({
  BootstrapData? bootstrap,
  Object? error,
  List<Uri>? launchedInto,
}) {
  return ProviderScope(
    overrides: [
      bootstrapProvider.overrideWith((ref) async {
        if (error != null) throw error;
        return bootstrap ?? _bootstrap();
      }),
      urlLauncherProvider.overrideWithValue((url) async {
        launchedInto?.add(url);
        return true;
      }),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showContactShortcutsSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows all three real shortcuts when all are set',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('contact-whatsapp-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('contact-phone-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('contact-email-row')), findsOneWidget);
    expect(find.text('+8801979891996'), findsNWidgets(2));
    expect(find.text('support@triptel.co'), findsOneWidget);
  });

  testWidgets('hides a shortcut whose field is null, keeps the rest',
      (tester) async {
    await tester.pumpWidget(_app(bootstrap: _bootstrap(whatsapp: null)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('contact-whatsapp-row')), findsNothing);
    expect(find.byKey(const ValueKey('contact-phone-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('contact-email-row')), findsOneWidget);
  });

  testWidgets(
      'shows a real empty state when all three fields are null, not a '
      'blank sheet or a crash', (tester) async {
    await tester.pumpWidget(_app(
      bootstrap: _bootstrap(whatsapp: null, phone: null, email: null),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('tapping WhatsApp launches the real wa.me link', (tester) async {
    final launched = <Uri>[];
    await tester.pumpWidget(_app(launchedInto: launched));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('contact-whatsapp-row')));
    await tester.pumpAndSettle();

    expect(launched, [Uri.parse('https://wa.me/8801979891996')]);
  });

  testWidgets('tapping Call us launches the real tel: link', (tester) async {
    final launched = <Uri>[];
    await tester.pumpWidget(_app(launchedInto: launched));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('contact-phone-row')));
    await tester.pumpAndSettle();

    expect(launched, [Uri(scheme: 'tel', path: '+8801979891996')]);
  });

  testWidgets('tapping Email us launches the real mailto: link',
      (tester) async {
    final launched = <Uri>[];
    await tester.pumpWidget(_app(launchedInto: launched));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('contact-email-row')));
    await tester.pumpAndSettle();

    expect(launched, [Uri(scheme: 'mailto', path: 'support@triptel.co')]);
  });

  testWidgets('a load error shows a real message, not a crash', (tester) async {
    await tester.pumpWidget(_app(error: Exception('network error')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load contact details."), findsOneWidget);
  });
}
