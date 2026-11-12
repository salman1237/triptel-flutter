import 'package:flutter/material.dart';
import '../../../core/money/currency_pill_switcher.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Home tab placeholder. Real content (hero, quick actions, promos) lands in
/// FR-201; this proves the FR-004 shell routes here and hosts FR-005's
/// currency pill until FR-201 moves it into the real hero header.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('home-tab'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: AppSpacing.gutter),
          const CurrencyPillSwitcher(),
          const EmptyState(
            icon: Icons.explore_outlined,
            message: 'Home — destinations and plans are coming in FR-201.',
          ),
        ],
      ),
    );
  }
}
