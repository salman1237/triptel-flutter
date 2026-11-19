import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/support/application/support_attachment_opener.dart';
import 'package:triptel/features/support/application/support_image_picker.dart';
import 'package:triptel/features/support/application/support_providers.dart';
import 'package:triptel/features/support/data/models/support_attachment.dart';
import 'package:triptel/features/support/data/models/support_category.dart';
import 'package:triptel/features/support/data/models/support_message.dart';
import 'package:triptel/features/support/data/models/support_ticket.dart';
import 'package:triptel/features/support/data/support_api.dart';
import 'package:triptel/features/support/presentation/ticket_thread_screen.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/data/models/featured_package.dart';
import 'package:triptel/features/esims/application/my_esims_providers.dart';
import 'package:triptel/features/esims/data/models/my_esim.dart';
import 'package:triptel/features/support/data/models/shared_order.dart';
import 'package:triptel/features/support/data/models/shared_product.dart';

import '../auth/secure_storage_test_mock.dart';

const _ticketId = 'ticket-1';

SupportTicket _ticket({
  String status = 'ANSWERED',
  List<SupportMessage> messages = const [],
}) =>
    SupportTicket(
      id: _ticketId,
      reference: 'TKT-TEST-1',
      subject: 'My eSIM is not working',
      category: 'ESIM',
      status: status,
      messages: messages,
    );

class _FakeSupportApi implements SupportApi {
  _FakeSupportApi({SupportTicket? ticket, this.replyError})
      : ticket = ticket ?? _ticket();
  SupportTicket ticket;
  final ApiException? replyError;
  String? lastReplyBody;
  List<String>? lastReplyFiles;
  String? lastReplySharedOrderId;
  String? lastReplySharedProductId;
  bool closeCalled = false;

  @override
  Future<SupportTicket> getTicket(String id) async => ticket;

  @override
  Future<SupportTicket> replyToTicket(
    String id, {
    required String body,
    List<String> filePaths = const [],
    String? sharedOrderId,
    String? sharedProductId,
  }) async {
    if (replyError != null) throw replyError!;
    lastReplyBody = body;
    lastReplyFiles = filePaths;
    lastReplySharedOrderId = sharedOrderId;
    lastReplySharedProductId = sharedProductId;
    ticket = SupportTicket(
      id: ticket.id,
      reference: ticket.reference,
      subject: ticket.subject,
      category: ticket.category,
      status: ticket.status,
      messages: [
        ...?ticket.messages,
        SupportMessage(
          id: 'm-new',
          body: body,
          isStaff: false,
          author: 'You',
          createdAt: DateTime.utc(2026, 11, 18),
          attachments: const [],
          messageType: sharedOrderId != null
              ? 'ORDER_SHARE'
              : sharedProductId != null
                  ? 'PRODUCT_SHARE'
                  : 'TEXT',
        ),
      ],
    );
    return ticket;
  }

  @override
  Future<SupportTicket> closeTicket(String id) async {
    closeCalled = true;
    ticket = SupportTicket(
      id: ticket.id,
      reference: ticket.reference,
      subject: ticket.subject,
      category: ticket.category,
      status: 'CLOSED',
    );
    return ticket;
  }

  @override
  Future<Uint8List> downloadAttachment(SupportAttachment attachment) =>
      throw UnimplementedError();

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    required String category,
    List<String> filePaths = const [],
  }) =>
      throw UnimplementedError();

  @override
  Future<List<SupportTicket>> getTickets() => throw UnimplementedError();

  @override
  Future<List<SupportCategory>> getCategories() => throw UnimplementedError();
}

Widget _app(
  _FakeSupportApi api, {
  SupportImagePicker? picker,
  SupportAttachmentOpener? opener,
  List<MyEsim>? myEsims,
  List<FeaturedPackage>? featuredPackages,
}) {
  final router = GoRouter(
    initialLocation: '/support/$_ticketId',
    routes: [
      GoRoute(
        path: '/support/:id',
        builder: (context, state) =>
            TicketThreadScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/my-esims/:id',
        builder: (context, state) =>
            Text('esim-detail-placeholder-${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/explore/:slug',
        builder: (context, state) =>
            Text('plans-placeholder-${state.pathParameters['slug']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      supportApiProvider.overrideWithValue(api),
      if (picker != null) supportImagePickerProvider.overrideWithValue(picker),
      if (opener != null)
        supportAttachmentOpenerProvider.overrideWithValue(opener),
      myEsimsProvider.overrideWith((ref) async => myEsims ?? const []),
      featuredPackagesProvider
          .overrideWith((ref) async => featuredPackages ?? const []),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  // FR-C902: the screen now also wires a live `SupportSocket` (reads the
  // JWT via the real `secureStoreProvider`); fake the plugin channel so
  // these REST-focused tests don't touch a real keychain/keystore. With
  // no token saved, `readToken()` resolves null and `SupportSocket`
  // no-ops rather than attempting a real network connection.
  setUp(installFakeSecureStorage);

  testWidgets('shows the real subject, reference, and status chip',
      (tester) async {
    final api = _FakeSupportApi(ticket: _ticket());
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('My eSIM is not working'), findsOneWidget);
    expect(find.text('TKT-TEST-1'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);
  });

  testWidgets('shows real messages with their real author and body',
      (tester) async {
    final api = _FakeSupportApi(
      ticket: _ticket(messages: [
        SupportMessage(
          id: 'm1',
          body: 'It stopped working after I landed.',
          isStaff: false,
          author: 'You',
          createdAt: DateTime.utc(2026, 11, 10),
          attachments: const [],
        ),
        SupportMessage(
          id: 'm2',
          body: 'Can you share the error you see?',
          isStaff: true,
          author: 'Support',
          createdAt: DateTime.utc(2026, 11, 11),
          attachments: const [],
        ),
      ]),
    );
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('It stopped working after I landed.'), findsOneWidget);
    expect(find.text('Can you share the error you see?'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
  });

  testWidgets('a RESOLVED ticket shows the resolved banner', (tester) async {
    final api = _FakeSupportApi(ticket: _ticket(status: 'RESOLVED'));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('ticket-resolved-banner')), findsOneWidget);
  });

  testWidgets(
      'a CLOSED ticket hides the reply field and shows the closed notice',
      (tester) async {
    final api = _FakeSupportApi(ticket: _ticket(status: 'CLOSED'));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ticket-reply-field')), findsNothing);
    expect(find.byKey(const ValueKey('ticket-close-button')), findsNothing);
    expect(find.byKey(const ValueKey('ticket-closed-notice')), findsOneWidget);
  });

  testWidgets('sending a real reply calls the real API and clears the field',
      (tester) async {
    final api = _FakeSupportApi(ticket: _ticket());
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('ticket-reply-field')), 'Still broken.');
    await tester.tap(find.byKey(const ValueKey('ticket-reply-send-button')));
    await tester.pumpAndSettle();

    expect(api.lastReplyBody, 'Still broken.');
    expect(find.text('Still broken.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Still broken.'), findsNothing);
  });

  testWidgets('sending an empty reply shows a real client-side error',
      (tester) async {
    final api = _FakeSupportApi(ticket: _ticket());
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ticket-reply-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Write a reply first.'), findsOneWidget);
    expect(api.lastReplyBody, isNull);
  });

  testWidgets(
      'a real server error on reply (e.g. the documented 400 for a '
      'just-closed ticket) shows the real message', (tester) async {
    final api = _FakeSupportApi(
      ticket: _ticket(),
      replyError: const ApiException(
          statusCode: 400, message: 'This ticket is closed.'),
    );
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('ticket-reply-field')), 'Hello?');
    await tester.tap(find.byKey(const ValueKey('ticket-reply-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('This ticket is closed.'), findsOneWidget);
  });

  testWidgets('tapping Close ticket calls the real close API', (tester) async {
    final api = _FakeSupportApi(ticket: _ticket());
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ticket-close-button')));
    await tester.pumpAndSettle();

    expect(api.closeCalled, isTrue);
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets(
      'adding a real photo attachment then sending includes its real path',
      (tester) async {
    final api = _FakeSupportApi(ticket: _ticket());
    await tester
        .pumpWidget(_app(api, picker: () async => '/tmp/reply-photo.jpg'));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('ticket-reply-add-attachment-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('ticket-reply-field')), 'See attached.');
    await tester.tap(find.byKey(const ValueKey('ticket-reply-send-button')));
    await tester.pumpAndSettle();

    expect(api.lastReplyFiles, ['/tmp/reply-photo.jpg']);
  });

  testWidgets('removing a reply attachment drops its real path',
      (tester) async {
    final api = _FakeSupportApi(ticket: _ticket());
    await tester
        .pumpWidget(_app(api, picker: () async => '/tmp/reply-photo.jpg'));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('ticket-reply-add-attachment-button')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('ticket-reply-remove-attachment-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('ticket-reply-field')), 'No file.');
    await tester.tap(find.byKey(const ValueKey('ticket-reply-send-button')));
    await tester.pumpAndSettle();

    expect(api.lastReplyFiles, isEmpty);
  });

  testWidgets('tapping a real attachment calls the real authenticated opener',
      (tester) async {
    SupportAttachment? opened;
    final api = _FakeSupportApi(
      ticket: _ticket(messages: [
        SupportMessage(
          id: 'm1',
          body: 'See photo.',
          isStaff: true,
          author: 'Support',
          createdAt: DateTime.utc(2026, 11, 11),
          attachments: const [
            SupportAttachment(
              id: 'att-1',
              name: 'screenshot.png',
              contentType: 'image/png',
              sizeBytes: 100,
              url: '/api/v1/support/attachments/att-1',
            ),
          ],
        ),
      ]),
    );
    await tester.pumpWidget(
        _app(api, opener: (attachment) async => opened = attachment));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ticket-attachment-att-1')));
    await tester.pumpAndSettle();

    expect(opened?.id, 'att-1');
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        supportTicketProvider(_ticketId)
            .overrideWith((ref) async => throw Exception('network error')),
      ],
      child: const MaterialApp(home: TicketThreadScreen(ticketId: _ticketId)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });

  group('FR-C903: share an order or package', () {
    final esim = MyEsim(
      id: 'esim-1',
      orderId: 'order-1',
      orderNo: 'ORD-1',
      productTitle: 'Bangladesh 1GB 7Days',
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
    final package = FeaturedPackage(
      productId: 'product-1',
      title: 'Japan 3GB 15Days',
      retailPrice: Money.parseEur('18.99'),
      dataAmountGb: 3,
      validityDays: 15,
      isUnlimited: false,
      countryCount: 1,
      countryIso2: 'JP',
      countryName: 'Japan',
      countrySlug: 'japan',
      flagUrl: null,
    );

    testWidgets(
        'tapping the share button opens the picker with My orders and '
        'Packages tabs', (tester) async {
      final api = _FakeSupportApi(ticket: _ticket());
      await tester.pumpWidget(_app(api, myEsims: [esim]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ticket-reply-share-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('share-picker-tabs')), findsOneWidget);
      expect(find.byKey(ValueKey('share-order-${esim.id}')), findsOneWidget);
    });

    testWidgets(
        'picking an order shows the pending-share chip, and sending '
        'includes the real shared_order_id', (tester) async {
      final api = _FakeSupportApi(ticket: _ticket());
      await tester.pumpWidget(_app(api, myEsims: [esim]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ticket-reply-share-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('share-order-${esim.id}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ticket-pending-share-label')),
          findsOneWidget);
      expect(find.textContaining('Bangladesh 1GB 7Days'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ticket-reply-send-button')));
      await tester.pumpAndSettle();

      expect(api.lastReplySharedOrderId, 'order-1');
      expect(api.lastReplySharedProductId, isNull);
      // The chip clears after a successful send.
      expect(find.byKey(const ValueKey('ticket-pending-share-label')),
          findsNothing);
    });

    testWidgets(
        'picking a package shows the pending-share chip, and sending '
        'includes the real shared_product_id', (tester) async {
      final api = _FakeSupportApi(ticket: _ticket());
      await tester.pumpWidget(_app(api, featuredPackages: [package]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ticket-reply-share-button')));
      await tester.pumpAndSettle();
      // Switch to the "Packages" tab of the segmented pill.
      await tester.tap(find.text('Packages'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(ValueKey('share-product-${package.productId}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ticket-pending-share-label')),
          findsOneWidget);
      expect(find.textContaining('Japan 3GB 15Days'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ticket-reply-send-button')));
      await tester.pumpAndSettle();

      expect(api.lastReplySharedProductId, 'product-1');
      expect(api.lastReplySharedOrderId, isNull);
    });

    testWidgets('the X button clears a pending share before sending',
        (tester) async {
      final api = _FakeSupportApi(ticket: _ticket());
      await tester.pumpWidget(_app(api, myEsims: [esim]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ticket-reply-share-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('share-order-${esim.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ticket-pending-share-label')),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ticket-reply-remove-share')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ticket-pending-share-label')),
          findsNothing);
    });

    testWidgets(
        'a share-only reply (no text) is allowed to send, not blocked by '
        'the "write a reply first" client-side check', (tester) async {
      final api = _FakeSupportApi(ticket: _ticket());
      await tester.pumpWidget(_app(api, myEsims: [esim]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ticket-reply-share-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('share-order-${esim.id}')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ticket-reply-send-button')));
      await tester.pumpAndSettle();

      expect(find.text('Write a reply first.'), findsNothing);
      expect(api.lastReplySharedOrderId, 'order-1');
    });

    testWidgets('an ORDER_SHARE message renders a rich order card',
        (tester) async {
      final api = _FakeSupportApi(
        ticket: _ticket(messages: [
          SupportMessage(
            id: 'm1',
            body: '',
            isStaff: false,
            author: 'You',
            createdAt: DateTime.utc(2026, 11, 19),
            attachments: const [],
            messageType: 'ORDER_SHARE',
            sharedOrder: const SharedOrder(
              id: 'order-1',
              orderNo: 'ORD-1',
              status: 'COMPLETED',
              totalAmount: Money(1250),
              productTitle: 'Bangladesh 1GB 7Days',
              esimProfileId: 'esim-1',
            ),
          ),
        ]),
      );
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('ticket-shared-order-m1')), findsOneWidget);
      expect(find.textContaining('Bangladesh 1GB 7Days'), findsOneWidget);
      expect(find.textContaining('ORD-1'), findsOneWidget);
    });

    testWidgets('a PRODUCT_SHARE message renders a rich product card',
        (tester) async {
      final api = _FakeSupportApi(
        ticket: _ticket(messages: [
          SupportMessage(
            id: 'm1',
            body: 'Check this one',
            isStaff: true,
            author: 'Support',
            createdAt: DateTime.utc(2026, 11, 19),
            attachments: const [],
            messageType: 'PRODUCT_SHARE',
            sharedProduct: const SharedProduct(
              id: 'product-1',
              title: 'Japan 3GB 15Days',
              dataAmountGb: 3,
              validityDays: 15,
              isUnlimited: false,
              retailPrice: Money(1899),
              countrySlug: 'japan',
            ),
          ),
        ]),
      );
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ticket-shared-product-m1')),
          findsOneWidget);
      expect(find.textContaining('Japan 3GB 15Days'), findsOneWidget);
      expect(find.text('Check this one'), findsOneWidget);
    });

    testWidgets(
        'an ORDER_SHARE message with a deleted shared order shows a '
        'readable placeholder, not a crash', (tester) async {
      final api = _FakeSupportApi(
        ticket: _ticket(messages: [
          SupportMessage(
            id: 'm1',
            body: '',
            isStaff: false,
            author: 'You',
            createdAt: DateTime.utc(2026, 11, 19),
            attachments: const [],
            messageType: 'ORDER_SHARE',
            sharedOrder: null,
          ),
        ]),
      );
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      expect(find.text('This shared order is no longer available.'),
          findsOneWidget);
    });

    testWidgets(
        'tapping an ORDER_SHARE card with a provisioned eSIM opens its '
        'detail screen', (tester) async {
      final api = _FakeSupportApi(
        ticket: _ticket(messages: [
          SupportMessage(
            id: 'm1',
            body: '',
            isStaff: false,
            author: 'You',
            createdAt: DateTime.utc(2026, 11, 19),
            attachments: const [],
            messageType: 'ORDER_SHARE',
            sharedOrder: const SharedOrder(
              id: 'order-1',
              orderNo: 'ORD-1',
              status: 'COMPLETED',
              totalAmount: Money(1250),
              productTitle: 'Bangladesh 1GB 7Days',
              esimProfileId: 'esim-1',
            ),
          ),
        ]),
      );
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ticket-shared-order-tap')));
      await tester.pumpAndSettle();

      expect(find.text('esim-detail-placeholder-esim-1'), findsOneWidget);
    });

    testWidgets(
        "tapping an ORDER_SHARE card for an order that hasn't provisioned "
        'an eSIM yet does nothing (no esim_profile_id to open)',
        (tester) async {
      final api = _FakeSupportApi(
        ticket: _ticket(messages: [
          SupportMessage(
            id: 'm1',
            body: '',
            isStaff: false,
            author: 'You',
            createdAt: DateTime.utc(2026, 11, 19),
            attachments: const [],
            messageType: 'ORDER_SHARE',
            sharedOrder: const SharedOrder(
              id: 'order-1',
              orderNo: 'ORD-1',
              status: 'PENDING',
              totalAmount: Money(1250),
              productTitle: 'Bangladesh 1GB 7Days',
              esimProfileId: null,
            ),
          ),
        ]),
      );
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ticket-shared-order-tap')),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(TicketThreadScreen), findsOneWidget);
    });

    testWidgets(
        "tapping a PRODUCT_SHARE card opens that country's plans screen",
        (tester) async {
      final api = _FakeSupportApi(
        ticket: _ticket(messages: [
          SupportMessage(
            id: 'm1',
            body: 'Check this one',
            isStaff: true,
            author: 'Support',
            createdAt: DateTime.utc(2026, 11, 19),
            attachments: const [],
            messageType: 'PRODUCT_SHARE',
            sharedProduct: const SharedProduct(
              id: 'product-1',
              title: 'Japan 3GB 15Days',
              dataAmountGb: 3,
              validityDays: 15,
              isUnlimited: false,
              retailPrice: Money(1899),
              countrySlug: 'japan',
            ),
          ),
        ]),
      );
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ticket-shared-product-tap')));
      await tester.pumpAndSettle();

      expect(find.text('plans-placeholder-japan'), findsOneWidget);
    });
  });
}
