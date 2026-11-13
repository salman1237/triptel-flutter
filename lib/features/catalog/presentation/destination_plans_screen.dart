import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/money/currency_format.dart';
import '../../../core/money/currency_pill_switcher.dart';
import '../../../core/money/currency_providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../checkout/presentation/pre_checkout_gate.dart';
import '../application/catalog_providers.dart';
import '../application/plan_shape.dart';
import '../application/share_destination.dart';
import '../data/models/destination.dart';
import '../data/models/product.dart';
import 'plan_detail_sheet.dart';

/// FR-204: destination plans screen (`/explore/<slug>`). Plan-type toggle
/// (only shapes that actually exist for this destination), a wheel picker
/// over the shape's primary dimension (data size for Fixed, validity days
/// for Day Pass/Unlimited -- docs/Design_System.md), and a radio list of
/// the plans matching the wheel's current value. Checkout (FR-301+)
/// doesn't exist yet, so "Continue" shows a "coming soon" snack instead of
/// routing to a path that doesn't exist (FR-105b-style reasoning).
class DestinationPlansScreen extends ConsumerStatefulWidget {
  const DestinationPlansScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<DestinationPlansScreen> createState() =>
      _DestinationPlansScreenState();
}

class _DestinationPlansScreenState
    extends ConsumerState<DestinationPlansScreen> {
  PlanShape? _shape;
  int _wheelIndex = 0;
  String? _selectedProductId;

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checkout is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinationAsync = ref.watch(destinationProvider(widget.slug));

    return Scaffold(
      key: const ValueKey('destination-plans-screen'),
      body: switch (destinationAsync) {
        AsyncData(:final value) => _Body(
            destination: value,
            shape: _shape,
            wheelIndex: _wheelIndex,
            selectedProductId: _selectedProductId,
            onShapeChanged: (shape) => setState(() {
              _shape = shape;
              _wheelIndex = 0;
              _selectedProductId = null;
            }),
            onWheelChanged: (index) => setState(() {
              _wheelIndex = index;
              _selectedProductId = null;
            }),
            onProductSelected: (id) => setState(() => _selectedProductId = id),
            onContinue: () => runPreCheckoutCompatibilityGate(
              context,
              ref,
              onContinue: () => _comingSoon(context),
            ),
          ),
        AsyncError() => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ErrorState(
                message: "We couldn't load this destination.",
                onRetry: () => ref.invalidate(destinationProvider(widget.slug)),
              ),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.destination,
    required this.shape,
    required this.wheelIndex,
    required this.selectedProductId,
    required this.onShapeChanged,
    required this.onWheelChanged,
    required this.onProductSelected,
    required this.onContinue,
  });

  final Destination destination;
  final PlanShape? shape;
  final int wheelIndex;
  final String? selectedProductId;
  final ValueChanged<PlanShape> onShapeChanged;
  final ValueChanged<int> onWheelChanged;
  final ValueChanged<String> onProductSelected;
  final VoidCallback onContinue;

  static const _shapeLabels = {
    PlanShape.fixed: 'Data',
    PlanShape.dayPass: 'Day Pass',
    PlanShape.unlimited: 'Unlimited',
  };

  @override
  Widget build(BuildContext context) {
    final grouped = groupByShape(destination.products);
    final availableShapes = [
      for (final s in PlanShape.values)
        if (grouped[s]?.isNotEmpty ?? false) s,
    ];
    final effectiveShape = (shape != null && availableShapes.contains(shape))
        ? shape!
        : (availableShapes.isEmpty ? PlanShape.fixed : availableShapes.first);
    final shapeProducts = grouped[effectiveShape] ?? const <Product>[];

    final wheelValues = effectiveShape == PlanShape.fixed
        ? fixedDataSizes(shapeProducts)
        : planValidityDays(shapeProducts).map((d) => d.toDouble()).toList();
    final wheelLabels = effectiveShape == PlanShape.fixed
        ? [for (final v in wheelValues) _fixedWheelLabel(v)]
        : [for (final v in wheelValues) '${v.toInt()} days'];
    final effectiveWheelIndex =
        wheelValues.isEmpty ? 0 : wheelIndex.clamp(0, wheelValues.length - 1);

    final matching = wheelValues.isEmpty
        ? const <Product>[]
        : shapeProducts.where((p) {
            final value = effectiveShape == PlanShape.fixed
                ? p.dataAmountGb
                : p.validityDays.toDouble();
            return (value - wheelValues[effectiveWheelIndex]).abs() < 0.001;
          }).toList()
      ..sort(
          (a, b) => a.retailPrice.eurCents.compareTo(b.retailPrice.eurCents));

    return Column(
      children: [
        _Header(country: destination.country),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (availableShapes.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedPill(
                        options: [
                          for (final s in availableShapes) _shapeLabels[s]!
                        ],
                        selectedIndex: availableShapes.indexOf(effectiveShape),
                        onChanged: (i) => onShapeChanged(availableShapes[i]),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (wheelLabels.isNotEmpty)
                    PlanWheelPicker(
                      key: ValueKey(effectiveShape),
                      labels: wheelLabels,
                      initialIndex: effectiveWheelIndex,
                      onChanged: onWheelChanged,
                    ),
                  const SizedBox(height: 16),
                  for (final product in matching)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final rateAsync =
                              ref.watch(selectedCurrencyRateProvider);
                          final currencyAsync =
                              ref.watch(currencyPreferenceProvider);
                          final priceText =
                              switch ((rateAsync, currencyAsync)) {
                            (
                              AsyncData(value: final rate),
                              AsyncData(value: final code)
                            ) =>
                              formatMoney(product.retailPrice,
                                  currencyCode: code, rateToBase: rate),
                            _ => '',
                          };
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              PlanOptionTile(
                                title: product.isFeatured
                                    ? '${product.titleEn}  ·  Recommended'
                                    : product.titleEn,
                                priceText: priceText,
                                coverageLabel: '${planDataLabel(product)} · '
                                    '${product.validityDays} days · '
                                    '${planCoverageLabel(product)}',
                                selected: product.id == selectedProductId,
                                onTap: () => onProductSelected(product.id),
                              ),
                              TextButton(
                                key: ValueKey('plan-details-${product.id}'),
                                onPressed: () => showPlanDetailSheet(
                                  context,
                                  product: product,
                                  countryName: destination.country.nameEn,
                                ),
                                child: const Text('Plan details'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  if (matching.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: EmptyState(
                        icon: Icons.sim_card_outlined,
                        message: 'No plans match this selection.',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        StickyTotalBar(
          totalText: selectedProductId == null ? 'Select a plan' : '',
          ctaLabel: 'Continue',
          onPressed: selectedProductId == null ? null : onContinue,
        ),
      ],
    );
  }

  String _fixedWheelLabel(double gb) =>
      gb < 1 ? '${(gb * 1000).round()} MB' : '${_trim(gb)} GB';

  String _trim(double v) {
    var text = v.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.country});

  final dynamic country;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, 12, AppSpacing.gutter, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.night, AppColors.primaryDeep],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.surface),
                ),
                const Spacer(),
                IconButton(
                  key: const ValueKey('share-destination-button'),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: destinationShareUrl(country.slug),
                      subject: country.nameEn,
                    ),
                  ),
                  icon: const Icon(Icons.share, color: AppColors.surface),
                ),
                const CurrencyPillSwitcher(),
              ],
            ),
            const SizedBox(height: 4),
            FlagAvatar(flagUrl: country.flagUrl, size: 56),
            const SizedBox(height: 8),
            Text(
              country.nameEn,
              style: AppTypography.title(color: AppColors.surface),
            ),
          ],
        ),
      ),
    );
  }
}
