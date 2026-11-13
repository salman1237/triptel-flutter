import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/wallet/application/wallet_balance.dart';
import 'package:triptel/features/wallet/data/models/wallet.dart';

const _default =
    Wallet(walletType: 'DEFAULT', balance: Money(300), isFrozen: false);
const _reward =
    Wallet(walletType: 'REWARD', balance: Money(100), isFrozen: false);
const _commission =
    Wallet(walletType: 'COMMISSION', balance: Money(500), isFrozen: false);

void main() {
  group('spendableBalance', () {
    test('sums DEFAULT and REWARD, ignoring COMMISSION', () {
      expect(
          spendableBalance([_default, _reward, _commission]), const Money(400));
    });

    test('empty wallet list is zero', () {
      expect(spendableBalance(const []), const Money(0));
    });

    test('COMMISSION-only balance never counts as spendable', () {
      expect(spendableBalance([_commission]), const Money(0));
    });
  });

  group('walletCoversTotal', () {
    test('true when spendable balance equals the total exactly', () {
      expect(walletCoversTotal([_default, _reward], const Money(400)), isTrue);
    });

    test('true when spendable balance exceeds the total', () {
      expect(walletCoversTotal([_default, _reward], const Money(100)), isTrue);
    });

    test('false when spendable balance falls short', () {
      expect(walletCoversTotal([_default, _reward], const Money(500)), isFalse);
    });

    test('a guest (no wallets) never covers any positive total', () {
      expect(walletCoversTotal(const [], const Money(1)), isFalse);
    });
  });
}
