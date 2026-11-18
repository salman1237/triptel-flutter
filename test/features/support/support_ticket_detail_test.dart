import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/support/data/models/support_ticket.dart';

void main() {
  test(
      'SupportTicket.fromJson parses the documented GET /support/tickets/'
      '{id} response including the messages thread (API.md section 12)', () {
    final json = jsonDecode(
      File('test/fixtures/support_ticket_detail.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final ticket = SupportTicket.fromJson(json);

    expect(ticket.reference, 'TKT-261118-E5EB0');
    expect(ticket.status, 'CLOSED');
    expect(ticket.closedAt, isNotNull);
    expect(ticket.messages, hasLength(2));
    expect(ticket.messages![0].author, 'Support');
    expect(ticket.messages![0].isStaff, isTrue);
    expect(ticket.messages![0].body, 'Confirming list refreshes after submit.');
    expect(ticket.messages![0].attachments, isEmpty);
  });

  test(
      'SupportTicket.fromJson leaves messages null when absent (the list '
      'and close-ticket responses don\'t include it)', () {
    final ticket = SupportTicket.fromJson(const {
      'id': 't1',
      'reference': 'TKT-1',
      'subject': 'Subject',
      'category': 'OTHER',
      'status': 'CLOSED',
    });

    expect(ticket.messages, isNull);
  });
}
