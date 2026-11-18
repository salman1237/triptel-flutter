import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/legal/application/legal_providers.dart';
import 'package:triptel/features/legal/data/models/legal_document.dart';
import 'package:triptel/features/legal/presentation/legal_document_screen.dart';

const _document = LegalDocumentDetail(
  slug: 'privacy',
  title: 'Privacy Policy',
  body: '## Information we collect\n'
      '- **Account details:** name, email.\n'
      '- Technical data.\n\n'
      'We do not sell your personal information.',
  updatedAt: null,
);

Widget _app({Object result = _document}) {
  return ProviderScope(
    overrides: [
      legalDocumentProvider('privacy').overrideWith((ref) async {
        if (result is Exception) throw result;
        return result as LegalDocumentDetail;
      }),
    ],
    child: const MaterialApp(
      home: LegalDocumentScreen(slug: 'privacy'),
    ),
  );
}

void main() {
  testWidgets('shows the real title in the AppBar', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets('renders the real heading, bullets, and paragraph',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Information we collect'), findsOneWidget);
    expect(find.textContaining('We do not sell your personal information.'),
        findsOneWidget);
    expect(find.textContaining('Technical data.'), findsOneWidget);
  });

  testWidgets('shows the real updated_at date when present', (tester) async {
    await tester.pumpWidget(_app(
      result: LegalDocumentDetail(
        slug: 'privacy',
        title: 'Privacy Policy',
        body: 'Body.',
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nov 1, 2026'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(_app(result: Exception('network error')));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('shows a loading indicator while the provider resolves',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        legalDocumentProvider('privacy')
            .overrideWith((ref) => Completer<LegalDocumentDetail>().future),
      ],
      child: const MaterialApp(home: LegalDocumentScreen(slug: 'privacy')),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
