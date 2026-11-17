import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/support/data/models/support_ticket.dart';

void main() {
  test(
      'SupportTicket.fromJson parses the real beta POST/GET '
      '/support/tickets shape (API.md section 12)', () {
    final json =
        jsonDecode(File('test/fixtures/support_ticket.json').readAsStringSync())
            as Map<String, dynamic>;

    final ticket = SupportTicket.fromJson(json);

    expect(ticket.id, '449cdb4d-2c25-4ba0-8c56-1eb576fdd248');
    expect(ticket.reference, 'TKT-261110-9A1CD');
    expect(ticket.category, 'OTHER');
    expect(ticket.status, 'ANSWERED');
    expect(ticket.orderId, isNull);
    expect(
        ticket.createdAt, DateTime.parse('2026-11-10T14:55:37.673223+00:00'));
    expect(ticket.lastMessageAt,
        DateTime.parse('2026-11-10T14:55:37.763231+00:00'));
    expect(ticket.resolvedAt, isNull);
    expect(ticket.closedAt, isNull);
  });
}
