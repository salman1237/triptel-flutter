import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../application/plan_shape.dart';
import '../data/models/product.dart';

/// FR-205: plan detail / coverage sheet. Shows the full (disambiguating)
/// title -- several products can share the same data+validity, differing
/// only by supplier suffix (API.md §3: "Japan 1GB 7Days" vs "(IIJ)" vs
/// "(nonhkip)") -- plan facts, and the coverage list for regional plans
/// (plain country name + "1 country" for the normal, single-country case
/// this app's own destination page always produces, same reasoning as
/// FR-204's row-level coverage label).
Future<void> showPlanDetailSheet(
  BuildContext context, {
  required Product product,
  required String countryName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        PlanDetailSheet(product: product, countryName: countryName),
  );
}

class PlanDetailSheet extends StatelessWidget {
  const PlanDetailSheet(
      {super.key, required this.product, required this.countryName});

  final Product product;
  final String countryName;

  @override
  Widget build(BuildContext context) {
    final coverage = product.coverageCountries;
    final isRegionalCoverage = coverage != null && coverage.isNotEmpty;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
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
                  key: const ValueKey('plan-detail-title'),
                  child: Text(product.titleEn, style: AppTypography.headline()),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, 8, AppSpacing.gutter, AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Fact(
                        icon: Icons.sim_card_outlined,
                        label: _dataTypeLabel(planShape(product)),
                      ),
                      const _Fact(
                        icon: Icons.play_circle_outline,
                        label: 'Starts on install',
                      ),
                      const _Fact(
                        icon: Icons.wifi_tethering,
                        label: 'Personal hotspot',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isRegionalCoverage) ...[
                    Text('Coverage', style: AppTypography.label()),
                    const SizedBox(height: 10),
                    Text('${coverage.length} countries',
                        style: AppTypography.body(color: AppColors.inkMuted)),
                    const SizedBox(height: 8),
                    for (final country in coverage)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.public,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(country, style: AppTypography.body()),
                          ],
                        ),
                      ),
                  ] else ...[
                    Text('Coverage', style: AppTypography.label()),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.public,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text('$countryName · 1 country',
                            style: AppTypography.body()),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dataTypeLabel(PlanShape shape) => switch (shape) {
        PlanShape.fixed => 'Fixed data',
        PlanShape.dayPass => 'Day pass',
        PlanShape.unlimited => 'Unlimited',
      };
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 26),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.caption(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}
