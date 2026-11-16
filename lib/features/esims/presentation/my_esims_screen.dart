import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/esim_card_shape.dart';
import '../application/my_esims_providers.dart';
import '../data/models/my_esim.dart';

/// FR-402: `GET /orders/my-esims` cards -- plan title, status chip,
/// data/validity, "starts on install" or expiry; pull to refresh; empty
/// state routes to Home to explore destinations.
class MyEsimsScreen extends ConsumerWidget {
  const MyEsimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esimsAsync = ref.watch(myEsimsProvider);

    return TriptelScaffold(
      key: const ValueKey('my-esims-tab'),
      scrollable: false,
      body: switch (esimsAsync) {
        AsyncData(:final value) when value.isEmpty => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myEsimsProvider);
              await ref.read(myEsimsProvider.future);
            },
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: EmptyState(
                    icon: Icons.sim_card_outlined,
                    message:
                        "You haven't bought an eSIM yet -- explore destinations "
                        'to get started.',
                    ctaLabel: 'Explore destinations',
                    onCtaPressed: () => context.go('/home'),
                  ),
                ),
              ],
            ),
          ),
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myEsimsProvider);
              await ref.read(myEsimsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter, vertical: 12),
              itemCount: value.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _EsimCard(esim: value[index]),
            ),
          ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load your eSIMs.",
              onRetry: () => ref.invalidate(myEsimsProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _EsimCard extends StatelessWidget {
  const _EsimCard({required this.esim});

  final MyEsim esim;

  @override
  Widget build(BuildContext context) {
    final chip = esimStatusChip(esim.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [appCardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(esim.productTitle,
                    style: AppTypography.body(), maxLines: 2),
              ),
              const SizedBox(width: 8),
              StatusChip(label: chip.label, tone: chip.tone),
            ],
          ),
          const SizedBox(height: 6),
          Text('${esimDataLabel(esim)} · ${esimValidityLabel(esim)}',
              style: AppTypography.caption(color: AppColors.inkMuted)),
          const SizedBox(height: 4),
          Text(esimOwnershipLabel(esim),
              style: AppTypography.caption(color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
