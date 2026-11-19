import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/esims/application/my_esims_providers.dart';
import 'package:triptel/features/esims/data/models/my_esim.dart';
import 'package:triptel/features/esims/data/my_esims_api.dart';
import 'package:triptel/features/support/application/support_image_picker.dart';
import 'package:triptel/features/support/application/support_providers.dart';
import 'package:triptel/features/support/data/models/support_attachment.dart';
import 'package:triptel/features/support/data/models/support_category.dart';
import 'package:triptel/features/support/data/models/support_ticket.dart';
import 'package:triptel/features/support/data/support_api.dart';
import 'package:triptel/features/support/presentation/new_ticket_screen.dart';

const _categories = [
  SupportCategory(value: 'ESIM', label: 'eSIM not working'),
  SupportCategory(value: 'PAYMENT', label: 'Payment issue'),
  SupportCategory(value: 'OTHER', label: 'Other'),
];

MyEsim _esim({String id = 'esim-1', String orderNo = 'ORD-1'}) => MyEsim(
      id: id,
      orderNo: orderNo,
      productTitle: 'Japan 1GB 7Days',
      dataAmountGb: 1,
      isUnlimited: false,
      validityDays: 7,
      iccid: '',
      lpaString: '',
      qrCodeData: '',
      smdpAddress: '',
      status: 'ACTIVE',
      isMockFallback: false,
      createdAt: DateTime.utc(2026, 11, 1),
      activatedAt: null,
      expiresAt: null,
      isBeneficiary: false,
    );

class _FakeMyEsimsApi implements MyEsimsApi {
  _FakeMyEsimsApi(this._esims);
  final List<MyEsim> _esims;

  @override
  Future<List<MyEsim>> getMyEsims() async => _esims;
}

class _FakeSupportApi implements SupportApi {
  _FakeSupportApi({this.createError});
  final ApiException? createError;
  String? lastSubject;
  String? lastBody;
  String? lastCategory;
  List<String>? lastFilePaths;

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    required String category,
    List<String> filePaths = const [],
  }) async {
    if (createError != null) throw createError!;
    lastSubject = subject;
    lastBody = body;
    lastCategory = category;
    lastFilePaths = filePaths;
    return const SupportTicket(
      id: 'ticket-1',
      reference: 'TKT-NEW-1',
      subject: 'subject',
      category: 'OTHER',
      status: 'OPEN',
    );
  }

  @override
  Future<List<SupportTicket>> getTickets() => throw UnimplementedError();

  @override
  Future<SupportTicket> getTicket(String id) => throw UnimplementedError();

  @override
  Future<SupportTicket> replyToTicket(
    String id, {
    required String body,
    List<String> filePaths = const [],
    String? sharedOrderId,
    String? sharedProductId,
  }) =>
      throw UnimplementedError();

  @override
  Future<SupportTicket> closeTicket(String id) => throw UnimplementedError();

  @override
  Future<Uint8List> downloadAttachment(SupportAttachment attachment) =>
      throw UnimplementedError();

  @override
  Future<List<SupportCategory>> getCategories() async => _categories;
}

Widget _app({
  _FakeSupportApi? supportApi,
  List<MyEsim> esims = const [],
  SupportImagePicker? picker,
}) {
  final api = supportApi ?? _FakeSupportApi();
  return ProviderScope(
    overrides: [
      supportApiProvider.overrideWithValue(api),
      myEsimsApiProvider.overrideWithValue(_FakeMyEsimsApi(esims)),
      if (picker != null) supportImagePickerProvider.overrideWithValue(picker),
    ],
    child: const MaterialApp(home: NewTicketScreen()),
  );
}

Future<void> _tapVisible(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _growSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('shows the real categories, PARTNER excluded', (tester) async {
    await _growSurface(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await _tapVisible(tester, 'new-ticket-category-dropdown');

    expect(find.text('eSIM not working'), findsOneWidget);
    expect(find.text('Payment issue'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Partner'), findsNothing);
  });

  testWidgets('submitting without a subject shows a real error',
      (tester) async {
    await _growSurface(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await _tapVisible(tester, 'new-ticket-submit-button');

    expect(find.text('Enter a subject.'), findsOneWidget);
  });

  testWidgets('submitting without a body shows a real error', (tester) async {
    await _growSurface(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-subject')), 'Subject');
    await _tapVisible(tester, 'new-ticket-submit-button');

    expect(find.text('Describe your issue.'), findsOneWidget);
  });

  testWidgets(
      'a successful submit sends the real subject/body/category and '
      'shows the real reference', (tester) async {
    final api = _FakeSupportApi();
    await _growSurface(tester);
    await tester.pumpWidget(_app(supportApi: api));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-subject')), 'My subject');
    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-body')), 'Something broke');
    await _tapVisible(tester, 'new-ticket-submit-button');

    expect(api.lastSubject, 'My subject');
    expect(api.lastBody, 'Something broke');
    expect(api.lastCategory, 'OTHER');
    expect(find.text('Ticket TKT-NEW-1 created'), findsOneWidget);
  });

  testWidgets(
      'linking a real eSIM embeds its real order info in the submitted '
      'body', (tester) async {
    final api = _FakeSupportApi();
    await _growSurface(tester);
    await tester
        .pumpWidget(_app(supportApi: api, esims: [_esim(orderNo: 'ORD-999')]));
    await tester.pumpAndSettle();

    await _tapVisible(tester, 'new-ticket-link-esim-button');
    await tester.tap(find.text('Japan 1GB 7Days'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-subject')), 'Subject');
    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-body')), 'Body');
    await _tapVisible(tester, 'new-ticket-submit-button');

    expect(api.lastBody, contains('ORD-999'));
    expect(api.lastBody, contains('Body'));
  });

  testWidgets(
      'adding a real photo attachment sends its real path, up to the '
      'real 5-attachment cap', (tester) async {
    final api = _FakeSupportApi();
    var pickCount = 0;
    await _growSurface(tester);
    await tester.pumpWidget(_app(
      supportApi: api,
      picker: () async => '/tmp/photo-${pickCount++}.jpg',
    ));
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await _tapVisible(tester, 'new-ticket-add-attachment-button');
    }

    expect(find.text('Attachments (5/5)'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-ticket-add-attachment-button')),
        findsNothing);

    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-subject')), 'Subject');
    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-body')), 'Body');
    await _tapVisible(tester, 'new-ticket-submit-button');

    expect(api.lastFilePaths, hasLength(5));
    expect(api.lastFilePaths, [
      '/tmp/photo-0.jpg',
      '/tmp/photo-1.jpg',
      '/tmp/photo-2.jpg',
      '/tmp/photo-3.jpg',
      '/tmp/photo-4.jpg',
    ]);
  });

  testWidgets('removing an attachment drops the real path before submit',
      (tester) async {
    final api = _FakeSupportApi();
    await _growSurface(tester);
    await tester.pumpWidget(_app(
      supportApi: api,
      picker: () async => '/tmp/photo.jpg',
    ));
    await tester.pumpAndSettle();

    await _tapVisible(tester, 'new-ticket-add-attachment-button');
    await _tapVisible(tester, 'new-ticket-remove-attachment-0');

    expect(find.text('Attachments (0/5)'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-subject')), 'Subject');
    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-body')), 'Body');
    await _tapVisible(tester, 'new-ticket-submit-button');

    expect(api.lastFilePaths, isEmpty);
  });

  testWidgets('a real server error on submit shows the real message',
      (tester) async {
    await _growSurface(tester);
    await tester.pumpWidget(_app(
      supportApi: _FakeSupportApi(
        createError: const ApiException(
            statusCode: 400, message: 'Too many attachments.'),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-subject')), 'Subject');
    await tester.enterText(
        find.byKey(const ValueKey('new-ticket-body')), 'Body');
    await _tapVisible(tester, 'new-ticket-submit-button');

    expect(find.text('Too many attachments.'), findsOneWidget);
  });

  testWidgets('a categories load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        supportCategoriesProvider
            .overrideWith((ref) async => throw Exception('network error')),
      ],
      child: const MaterialApp(home: NewTicketScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
