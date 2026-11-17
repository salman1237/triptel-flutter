import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/wallet/data/models/ledger_entry.dart';

void main() {
  test(
      'LedgerEntry.fromJson parses the real beta GET /wallets/ledger shape '
      '(API.md section 5; captured from the real signed-in account on-'
      'device -- see claude-progress.md)', () {
    final json =
        jsonDecode(File('test/fixtures/wallets_ledger.json').readAsStringSync())
            as List;
    final entries = json.map((e) => LedgerEntry.fromJson(e)).toList();

    expect(entries, hasLength(5));

    final topup = entries[0];
    expect(topup.txType, 'DEBIT');
    expect(topup.isCredit, isFalse);
    expect(topup.amount.eurCents, 486);
    expect(topup.balanceAfter.eurCents, 51951);
    expect(topup.referenceType, 'ESIM_TOPUP_PURCHASE');
    expect(topup.description, 'Top-up: Saudi Arabia 1GB 7Days');
    expect(topup.createdAt, DateTime.parse('2026-11-16T20:59:37.271478Z'));

    final refund = entries[2];
    expect(refund.txType, 'CREDIT');
    expect(refund.isCredit, isTrue);
    expect(refund.referenceType, 'REFUND');
  });

  test('a real amount of "500.0000" parses to 50000 eur-cents', () {
    final entry = LedgerEntry.fromJson(const {
      'tx_type': 'CREDIT',
      'amount': '500.0000',
      'balance_after': '500.0000',
      'reference_type': 'ADMIN_ADJUSTMENT',
      'description': null,
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(entry.amount.eurCents, 50000);
    expect(entry.description, isNull);
  });

  group('ledgerReferenceLabel', () {
    test('every documented reference_type (API.md section 5) has a human label',
        () {
      const documented = [
        'DEPOSIT_GATEWAY',
        'DEPOSIT_MANUAL',
        'ORDER_PURCHASE',
        'COMMISSION_EARNED',
        'ADMIN_ADJUSTMENT',
        'REFUND',
        'COMMISSION_TRANSFER',
        'WITHDRAWAL_HOLD',
        'WITHDRAWAL_REVERSED',
        'REWARD_EARNED',
        'REWARD_REVERSED',
        'AGENT_COMMISSION_EARNED',
        'ESIM_TOPUP_PURCHASE',
      ];
      for (final type in documented) {
        expect(ledgerReferenceLabel(type), isNot(type),
            reason: '$type should have a human label, not fall back to raw');
      }
    });

    test('an undocumented future type falls back to the raw value', () {
      expect(ledgerReferenceLabel('SOME_NEW_TYPE'), 'SOME_NEW_TYPE');
    });
  });
}
