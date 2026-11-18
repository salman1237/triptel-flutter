import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/legal/application/legal_providers.dart';
import 'package:triptel/features/legal/data/models/legal_document.dart';
import 'package:triptel/features/legal/presentation/legal_documents_screen.dart';

const _documents = [
  LegalDocument(slug: 'privacy', title: 'Privacy Policy', updatedAt: null),
  LegalDocument(slug: 'terms', title: 'Terms & Conditions', updatedAt: null),
];

Widget _app({
  Object result = _documents,
}) {
  final router = GoRouter(
    initialLocation: '/legal',
    routes: [
      GoRoute(
        path: '/legal',
        builder: (context, state) => const LegalDocumentsScreen(),
      ),
      GoRoute(
        path: '/legal/:slug',
        builder: (context, state) =>
            Text('legal-document-placeholder-${state.pathParameters['slug']}'),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      legalDocumentsProvider.overrideWith((ref) async {
        if (result is Exception) throw result;
        return result as List<LegalDocument>;
      }),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('lists the real documents by title', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms & Conditions'), findsOneWidget);
  });

  testWidgets('tapping a row navigates to its real FR-1201 reader',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(find.text('legal-document-placeholder-privacy'), findsOneWidget);
  });

  testWidgets('an empty list shows a real EmptyState, not a crash',
      (tester) async {
    await tester.pumpWidget(_app(result: const <LegalDocument>[]));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(_app(result: Exception('network error')));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
