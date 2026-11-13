import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/currency_pill_switcher.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../compatibility/presentation/compatibility_promo_card.dart';
import '../application/catalog_providers.dart';

/// FR-201 Home: dark hero (search entry + quick actions), promo cards,
/// popular destinations. The destination search sheet (FR-202) and
/// destination plans screen (FR-204) don't exist yet, so search/destination
/// taps show a "coming soon" snack instead of a dead or unsafe navigation
/// (same reasoning as FR-105b: don't route to a route that doesn't exist).
/// "My eSIMs" and "Top up" are deliberately not quick actions here -- the
/// bottom tab bar already covers "My eSIMs", and "Top up" would today just
/// land on the same Wallet tab (FR-408's real top-up flow doesn't exist
/// yet) -- both would be redundant duplicate buttons rather than real
/// shortcuts. Revisit once FR-408 gives "Top up" something distinct to do.
/// Signed-in users' usage-summary-instead-of-hero variant needs FR-402/403
/// (not built) -> deferred as FR-201b.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularAsync = ref.watch(popularCountriesProvider);

    return TriptelScaffold(
      key: const ValueKey('home-tab'),
      scrollable: true,
      hero: HeroHeader(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _comingSoon(context, 'Destination search'),
                    child: const AbsorbPointer(
                      child: SearchPill(hintText: 'Find your destination'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _QuickAction(
                  icon: Icons.add_circle_outline,
                  label: 'Buy data',
                  onTap: () => _comingSoon(context, 'Buying data'),
                ),
              ],
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.gutter),
            const Align(
              alignment: Alignment.centerRight,
              child: CurrencyPillSwitcher(),
            ),
            const SizedBox(height: 16),
            const CompatibilityPromoCard(),
            const SizedBox(height: 20),
            Text('Popular destinations', style: AppTypography.headline()),
            const SizedBox(height: 12),
            switch (popularAsync) {
              AsyncData(:final value) => value.isEmpty
                  ? const EmptyState(
                      icon: Icons.explore_outlined,
                      message: 'No popular destinations right now.',
                    )
                  : Column(
                      children: [
                        for (final country in value)
                          CountryRow(
                            name: country.nameEn,
                            flagUrl: country.flagUrl,
                            onTap: () => _comingSoon(context, country.nameEn),
                          ),
                      ],
                    ),
              AsyncError() => ErrorState(
                  message: "We couldn't load popular destinations.",
                  onRetry: () => ref.invalidate(popularCountriesProvider),
                ),
              _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
            },
            const SizedBox(height: AppSpacing.gutter),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: AppColors.nightSoft, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.surface, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTypography.caption(color: AppColors.surface)),
          ],
        ),
      ),
    );
  }
}
