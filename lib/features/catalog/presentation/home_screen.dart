import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/money/currency_pill_switcher.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../../compatibility/presentation/compatibility_promo_card.dart';
import '../../esims/application/esim_status_providers.dart';
import '../../esims/application/my_esims_providers.dart';
import '../../support/application/support_providers.dart';
import '../application/catalog_providers.dart';
import '../application/home_usage_card_shape.dart';
import 'explore_sheet.dart';
import 'home_usage_card.dart';

/// Guards [_openSupportChat] against a rapid double-tap: without this, two
/// taps before the first `getTickets()` call resolves would both see "no
/// open ticket" and both call `createTicket`, creating two duplicate
/// tickets from one tap -- same class of bug `TicketThreadScreen`'s own
/// `_sending`/`_closing` flags already guard against for its buttons.
final _openingSupportChatProvider = StateProvider<bool>((ref) => false);

/// FR-C904: opens the signed-in user's own open ticket thread (FR-C902,
/// live chat), or starts a new empty ticket first if none is open
/// (anything but CLOSED counts as open -- a RESOLVED/ANSWERED ticket can
/// still be replied to, same rule `TicketThreadScreen` itself uses).
Future<void> _openSupportChat(BuildContext context, WidgetRef ref) async {
  if (ref.read(_openingSupportChatProvider)) return;
  ref.read(_openingSupportChatProvider.notifier).state = true;
  try {
    final tickets = await ref.read(supportApiProvider).getTickets();
    String? openTicketId;
    for (final t in tickets) {
      if (t.status != 'CLOSED') {
        openTicketId = t.id;
        break;
      }
    }
    final String ticketId;
    if (openTicketId != null) {
      ticketId = openTicketId;
    } else {
      final created = await ref.read(supportApiProvider).createTicket(
            subject: 'Chat with Support',
            body: '',
            category: 'OTHER',
          );
      ticketId = created.id;
    }
    if (!context.mounted) return;
    context.push('/support/$ticketId');
  } on ApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.message)));
  } finally {
    ref.read(_openingSupportChatProvider.notifier).state = false;
  }
}

/// FR-201 Home: dark hero (search entry + quick actions), promo cards,
/// popular destinations. The search pill and "Buy data" both open FR-202's
/// explore sheet. Destination-row taps now navigate to FR-204's plans
/// screen. "My eSIMs" and "Top up" are deliberately not quick actions here
/// -- the bottom tab bar already covers "My eSIMs", and "Top up" would
/// today just land on the same Wallet tab (FR-408's real top-up flow
/// doesn't exist yet) -- both would be redundant duplicate buttons rather
/// than real shortcuts. Revisit once FR-408 gives "Top up" something
/// distinct to do. FR-201b: a signed-in user with a real ACTIVE/INSTALLED
/// eSIM (`activeEsimForHomeCard`) sees FR-403's own usage data in
/// `HomeUsageCard` instead of this hero -- fails soft back to the plain
/// hero while that data is loading or on any error, since this is a
/// nice-to-have, never a reason to block the Home tab.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularAsync = ref.watch(popularCountriesProvider);
    final authState = ref.watch(authNotifierProvider).value;
    final openingChat = ref.watch(_openingSupportChatProvider);

    return TriptelScaffold(
      key: const ValueKey('home-tab'),
      scrollable: true,
      hero: authState is AuthAuthenticated
          ? const _SignedInHero()
          : const _DefaultHero(),
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
            if (authState is AuthAuthenticated) ...[
              const SizedBox(height: 12),
              PillButton(
                key: const ValueKey('home-chat-with-support'),
                label: 'Chat with Support',
                variant: PillButtonVariant.secondary,
                onPressed:
                    openingChat ? null : () => _openSupportChat(context, ref),
              ),
            ],
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
                            onTap: () =>
                                context.push('/explore/${country.slug}'),
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

class _DefaultHero extends StatelessWidget {
  const _DefaultHero();

  @override
  Widget build(BuildContext context) {
    return HeroHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Travel smart.\nStay connected.',
            style: AppTypography.title(color: AppColors.surface),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: const ValueKey('home-search-entry'),
                  onTap: () => showExploreSheet(context),
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
                onTap: () => showExploreSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// FR-201b: resolves the signed-in user's real eSIMs, then their real
/// usage, before deciding what to show -- any loading/error state along
/// the way falls back to [_DefaultHero] rather than blocking Home on data
/// this card treats as a bonus, not a requirement.
class _SignedInHero extends ConsumerWidget {
  const _SignedInHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esimsAsync = ref.watch(myEsimsProvider);
    final esims = esimsAsync.valueOrNull;
    if (esims == null) return const _DefaultHero();

    final activeEsim = activeEsimForHomeCard(esims, DateTime.now());
    if (activeEsim == null) return const _DefaultHero();

    final statusAsync = ref.watch(esimStatusProvider(activeEsim.id));
    final status = statusAsync.valueOrNull;
    if (status == null) return const _DefaultHero();

    return HomeUsageCard(
      esim: activeEsim,
      status: status,
      onViewEsim: () => context.push('/my-esims/${activeEsim.id}'),
      onBuyMore: () => showExploreSheet(context),
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
