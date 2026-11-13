import 'package:flutter/material.dart';
import '../../../core/money/currency_pill_switcher.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../compatibility/presentation/compatibility_promo_card.dart';

/// Home tab placeholder. Real content (hero, quick actions, promos) lands in
/// FR-201; this proves the FR-004 shell routes here and hosts FR-005's
/// currency pill until FR-201 moves it into the real hero header. FR-953's
/// device-check promo card is an early version of the "promos" Design_System
/// describes for the real FR-201 hero; it'll move there when that lands.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('home-tab'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.gutter),
          const Align(
            alignment: Alignment.centerRight,
            child: CurrencyPillSwitcher(),
          ),
          const SizedBox(height: 16),
          const CompatibilityPromoCard(),
          const EmptyState(
            icon: Icons.explore_outlined,
            message: 'Home — destinations and plans are coming in FR-201.',
          ),
        ],
      ),
    );
  }
}
