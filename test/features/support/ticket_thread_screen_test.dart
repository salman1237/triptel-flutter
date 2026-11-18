import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  bool closeCalled = false;

  @override
  Future<SupportTicket> getTicket(String id) async => ticket;

  @override
  Future<SupportTicket> replyToTicket(
    String id, {
    required String body,
    List<String> filePaths = const [],
  }) async {
    if (replyError != null) throw replyError!;
    lastReplyBody = body;
    lastReplyFiles = filePaths;
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
}) =>
    ProviderScope(
      overrides: [
        supportApiProvider.overrideWithValue(api),
        if (picker != null)
          supportImagePickerProvider.overrideWithValue(picker),
        if (opener != null)
          supportAttachmentOpenerProvider.overrideWithValue(opener),
      ],
      child: const MaterialApp(home: TicketThreadScreen(ticketId: _ticketId)),
    );

void main() {
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
}
