import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/widgets/widgets.dart';

/// Renders every FR-001 shared component for visual/device verification.
/// Superseded as a route once FR-004's shell lands; kept as a dev screen.
class ThemePreviewScreen extends StatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('fr-001-preview'),
      hero: HeroHeader(
        child: Text('Triptel',
            style: AppTypography.title(color: AppColors.surface)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const SearchPill(),
          const SizedBox(height: 16),
          SegmentedPill(
            options: const ['Country', 'Regional'],
            selectedIndex: _segment,
            onChanged: (i) => setState(() => _segment = i),
          ),
          const SizedBox(height: 16),
          const CountryRow(name: 'Thailand', subtitle: '5G'),
          const SizedBox(height: 16),
          const BalanceCard(
            title: 'Wallet balance',
            amountText: '€24.50',
            stats: [('Earned', '€12.00'), ('Used', '€4.00')],
          ),
          const SizedBox(height: 16),
          const ListGroup(children: [
            ListRow(icon: Icons.person_outline, title: 'Profile'),
            ListRow(
                icon: Icons.verified_user_outlined,
                title: 'KYC',
                subtitle: 'Not verified'),
          ]),
          const SizedBox(height: 16),
          const InfoBox(text: 'Data resets daily at midnight local time.'),
          const SizedBox(height: 16),
          const Wrap(spacing: 8, children: [
            StatusChip(label: 'Active', tone: StatusTone.success),
            StatusChip(label: 'Preparing', tone: StatusTone.warning),
            StatusChip(label: 'Failed', tone: StatusTone.danger),
          ]),
          const SizedBox(height: 16),
          const PlanOptionTile(
              title: '5 GB / 30 days', priceText: '€9.99', selected: true),
          const SizedBox(height: 16),
          const UsageRing(fraction: 0.4, centerText: '2.0 / 5 GB'),
          const SizedBox(height: 16),
          const EmptyState(
              icon: Icons.sim_card_outlined, message: 'No eSIMs yet.'),
          const SizedBox(height: 24),
        ],
      ),
      bottomBar: StickyTotalBar(
        totalText: '€9.99',
        ctaLabel: 'Checkout',
        onPressed: () {},
      ),
    );
  }
}
