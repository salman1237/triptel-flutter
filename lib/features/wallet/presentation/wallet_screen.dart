import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';

/// Wallet tab placeholder. Real balance/ledger land in FR-601/602.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('wallet-tab'),
      body: const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        message: 'Wallet — balance and top-ups are coming in FR-601.',
      ),
    );
  }
}
