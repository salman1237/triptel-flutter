import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/catalog_providers.dart';

/// FR-203: a regional package's coverage list -- "Globe icon rows, name,
/// 'N countries' link -> coverage list sheet" (docs/Functional_Requirements.md).
Future<void> showCoverageSheet(
  BuildContext context, {
  required String iso2,
  required String name,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CoverageSheet(iso2: iso2, name: name),
  );
}

class CoverageSheet extends ConsumerWidget {
  const CoverageSheet({super.key, required this.iso2, required this.name});

  final String iso2;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverageAsync = ref.watch(coverageCountriesProvider(iso2));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.lilac50,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, 20, AppSpacing.gutter, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(name, style: AppTypography.headline()),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: switch (coverageAsync) {
              AsyncData(:final value) => value.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: EmptyState(
                        icon: Icons.public_off,
                        message: 'No coverage details available.',
                      ),
                    )
                  : ListView(
                      key: const ValueKey('coverage-list'),
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8,
                          AppSpacing.gutter, AppSpacing.gutter),
                      children: [
                        Text(
                          '${value.length} countries',
                          style: AppTypography.body(color: AppColors.inkMuted),
                        ),
                        const SizedBox(height: 8),
                        for (final country in value)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.public,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Text(country, style: AppTypography.body()),
                              ],
                            ),
                          ),
                      ],
                    ),
              AsyncError() => Padding(
                  padding: const EdgeInsets.all(32),
                  child: ErrorState(
                    message: "We couldn't load the coverage list.",
                    onRetry: () =>
                        ref.invalidate(coverageCountriesProvider(iso2)),
                  ),
                ),
              _ => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
            },
          ),
        ],
      ),
    );
  }
}
