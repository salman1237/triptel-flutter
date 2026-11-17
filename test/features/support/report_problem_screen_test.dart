import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/support/application/support_providers.dart';
import 'package:triptel/features/support/data/models/support_ticket.dart';
import 'package:triptel/features/support/data/support_api.dart';
import 'package:triptel/features/support/presentation/report_problem_screen.dart';

const _args = ReportProblemArgs(
  esimId: 'esim-1',
  orderNo: 'ORD-20261114-6D7389',
  planTitle: 'Japan 100MB 7Days',
);

class _FakeSupportApi implements SupportApi {
  _FakeSupportApi({this.result});
  final Object? result; // SupportTicket or Exception.
  String? lastSubject;
  String? lastBody;
  String? lastCategory;

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    required String category,
  }) async {
    lastSubject = subject;
    lastBody = body;
    lastCategory = category;
    final r = result;
    if (r is Exception) throw r;
    return r as SupportTicket? ??
        const SupportTicket(
          id: 'ticket-1',
          reference: 'TKT-TEST-1',
          subject: 'Problem',
          category: 'ESIM',
          status: 'OPEN',
        );
  }
}

Widget _app(SupportApi api) => ProviderScope(
      overrides: [supportApiProvider.overrideWithValue(api)],
      child: const MaterialApp(home: ReportProblemScreen(args: _args)),
    );

void main() {
  testWidgets('subject is prefilled with the real order no', (tester) async {
    await tester.pumpWidget(_app(_FakeSupportApi()));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
        find.byKey(const ValueKey('report-problem-subject')));
    expect(field.controller!.text, 'Problem with eSIM ORD-20261114-6D7389');
  });

  testWidgets(
      'submitting with an empty description shows a client-side '
      'error and never calls the API', (tester) async {
    final api = _FakeSupportApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('report-problem-submit')));
    await tester.pump();

    expect(
        find.text('Describe the problem before submitting.'), findsOneWidget);
    expect(api.lastSubject, isNull);
  });

  testWidgets(
      'a real submit sends category ESIM and embeds the order/eSIM id in '
      'the body (no order_id field -- the real FK value is unavailable '
      'here), then shows the real reference', (tester) async {
    final api = _FakeSupportApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('report-problem-body')),
        'eSIM stopped working after install.');
    await tester.tap(find.byKey(const ValueKey('report-problem-submit')));
    await tester.pumpAndSettle();

    expect(api.lastCategory, 'ESIM');
    expect(api.lastBody, contains('Japan 100MB 7Days'));
    expect(api.lastBody, contains('ORD-20261114-6D7389'));
    expect(api.lastBody, contains('esim-1'));
    expect(api.lastBody, contains('eSIM stopped working after install.'));
    expect(find.text('Ticket TKT-TEST-1 created'), findsOneWidget);
  });

  testWidgets('a real server error shows its message, never crashes',
      (tester) async {
    final api = _FakeSupportApi(
        result: const ApiException(statusCode: 400, message: 'Body too long'));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('report-problem-body')), 'Problem.');
    await tester.tap(find.byKey(const ValueKey('report-problem-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Body too long'), findsOneWidget);
  });
}
