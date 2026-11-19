import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../catalog/application/catalog_providers.dart';
import '../../catalog/data/models/featured_package.dart';
import '../../esims/application/my_esims_providers.dart';
import '../../esims/data/models/my_esim.dart';

/// FR-C903: what the user picked to share in a support message -- mutually
/// exclusive with each other (`shared_order_id`/`shared_product_id`,
/// API.md section 12).
sealed class ShareSelection {}

class ShareOrderSelection extends ShareSelection {
  ShareOrderSelection(this.esim);
  final MyEsim esim;
}

class ShareProductSelection extends ShareSelection {
  ShareProductSelection(this.package);
  final FeaturedPackage package;
}

/// FR-C903: a picker over the user's own `GET /orders/my-esims`-backed
/// orders or the catalog (here: `GET /catalog/featured`'s curated global
/// packages -- the same list already fetched for FR-202b's explore sheet,
/// not a new catalog-search flow).
Future<ShareSelection?> showSharePickerSheet(BuildContext context) {
  return showModalBottomSheet<ShareSelection>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (context) => const SharePickerSheet(),
  );
}

class SharePickerSheet extends ConsumerStatefulWidget {
  const SharePickerSheet({super.key});

  @override
  ConsumerState<SharePickerSheet> createState() => _SharePickerSheetState();
}

class _SharePickerSheetState extends ConsumerState<SharePickerSheet> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share with support', style: AppTypography.headline()),
            const SizedBox(height: 12),
            SegmentedPill(
              key: const ValueKey('share-picker-tabs'),
              options: const ['My orders', 'Packages'],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: _tab == 0 ? const _OrdersTab() : const _PackagesTab(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esimsAsync = ref.watch(myEsimsProvider);
    return switch (esimsAsync) {
      AsyncData(:final value) => value.isEmpty
          ? const Center(child: Text('No eSIM orders yet.'))
          : ListView.builder(
              key: const ValueKey('share-orders-list'),
              itemCount: value.length,
              itemBuilder: (context, i) {
                final esim = value[i];
                final shareable = esim.orderId != null;
                return ListTile(
                  key: ValueKey('share-order-${esim.id}'),
                  enabled: shareable,
                  leading: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.primary),
                  title: Text(esim.productTitle, style: AppTypography.body()),
                  subtitle: Text(
                    '${esim.orderNo} · ${esim.validityDays} days',
                    style: AppTypography.caption(color: AppColors.inkMuted),
                  ),
                  onTap: shareable
                      ? () =>
                          Navigator.of(context).pop(ShareOrderSelection(esim))
                      : null,
                );
              },
            ),
      AsyncError() => const Center(child: Text('Could not load your orders.')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _PackagesTab extends ConsumerWidget {
  const _PackagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(featuredPackagesProvider);
    return switch (packagesAsync) {
      AsyncData(:final value) => value.isEmpty
          ? const Center(child: Text('No packages available.'))
          : ListView.builder(
              key: const ValueKey('share-packages-list'),
              itemCount: value.length,
              itemBuilder: (context, i) {
                final package = value[i];
                return ListTile(
                  key: ValueKey('share-product-${package.productId}'),
                  leading: FlagAvatar(flagUrl: package.flagUrl, size: 28),
                  title: Text(package.title, style: AppTypography.body()),
                  subtitle: Text(
                    package.countryName,
                    style: AppTypography.caption(color: AppColors.inkMuted),
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(ShareProductSelection(package)),
                );
              },
            ),
      AsyncError() => const Center(child: Text('Could not load packages.')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
