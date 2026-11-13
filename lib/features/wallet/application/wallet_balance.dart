import '../../../core/money/money.dart';
import '../data/models/wallet.dart';

/// FR-305/API.md section 5: spendable at checkout = DEFAULT + REWARD
/// (REWARD is spent first by the backend, but the client only needs the
/// total to decide whether to offer Wallet as a payment method -- not the
/// split). COMMISSION is merchant/agent money, never spendable by a
/// customer.
Money spendableBalance(List<Wallet> wallets) {
  var total = const Money(0);
  for (final wallet in wallets) {
    if (wallet.walletType == 'DEFAULT' || wallet.walletType == 'REWARD') {
      total += wallet.balance;
    }
  }
  return total;
}

/// FR-305: Wallet is offered as a payment method only if it fully covers
/// the total; otherwise the app goes straight to ShurjoPay.
bool walletCoversTotal(List<Wallet> wallets, Money total) =>
    spendableBalance(wallets) >= total;
