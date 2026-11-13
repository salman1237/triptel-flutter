import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/wallet/data/models/wallet.dart';

void main() {
  test('parses the real beta GET /wallets/my-wallets fixture', () {
    final raw =
        File('test/fixtures/wallets_my_wallets_empty.json').readAsStringSync();
    final json = jsonDecode(raw) as List;
    final wallets = json.map((w) => Wallet.fromJson(w)).toList();

    expect(wallets, hasLength(2));
    expect(wallets[0].walletType, 'DEFAULT');
    expect(wallets[0].balance.eurCents, 0);
    expect(wallets[0].isFrozen, isFalse);
    expect(wallets[1].walletType, 'REWARD');
  });

  test('is_frozen defaults to false when absent', () {
    final wallet = Wallet.fromJson(const {
      'wallet_type': 'DEFAULT',
      'balance': '5.00',
    });
    expect(wallet.isFrozen, isFalse);
  });
}
