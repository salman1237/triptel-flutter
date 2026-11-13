import '../data/models/product.dart';

/// FR-204's plan-shape detection, kept pure/testable (Architecture.md,
/// API.md §3's detection table):
/// Fixed data: `supplier_period_num == null && !is_unlimited`.
/// Day Pass: `supplier_period_num != null`.
/// Unlimited: `is_unlimited == true`.
enum PlanShape { fixed, dayPass, unlimited }

PlanShape planShape(Product product) {
  if (product.isUnlimited) return PlanShape.unlimited;
  if (product.supplierPeriodNum != null) return PlanShape.dayPass;
  return PlanShape.fixed;
}

/// The data-size label per API.md §3: Fixed shows the plan size ("100 MB"
/// below 1 GB, else "{X} GB"); Day Pass shows the PER-DAY share ("{X}
/// GB/day") since `dataAmountGb` on a day pass is the total over all days;
/// Unlimited just says "Unlimited".
String planDataLabel(Product product) => switch (planShape(product)) {
      PlanShape.unlimited => 'Unlimited',
      PlanShape.fixed => _fixedDataLabel(product.dataAmountGb),
      PlanShape.dayPass =>
        '${_trimTrailingZeros(product.dataAmountGb / product.validityDays)} GB/day',
    };

String _fixedDataLabel(double gb) {
  if (gb < 1) return '${(gb * 1000).round()} MB';
  return '${_trimTrailingZeros(gb)} GB';
}

String _trimTrailingZeros(double value) {
  final rounded = (value * 100).round() / 100;
  var text = rounded.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return text;
}

/// Groups [products] by their plan shape, for the Data/Day Pass/Unlimited
/// toggle -- only shapes with at least one product should offer a tab
/// (API.md's plan shapes don't all exist for every destination).
Map<PlanShape, List<Product>> groupByShape(List<Product> products) {
  final groups = <PlanShape, List<Product>>{};
  for (final product in products) {
    (groups[planShape(product)] ??= []).add(product);
  }
  return groups;
}

/// Fixed plans' wheel dimension: distinct data sizes, ascending.
List<double> fixedDataSizes(List<Product> products) =>
    (products.map((p) => p.dataAmountGb).toSet().toList()..sort());

/// Day Pass/Unlimited plans' wheel dimension: distinct validity days,
/// ascending.
List<int> planValidityDays(List<Product> products) =>
    (products.map((p) => p.validityDays).toSet().toList()..sort());

/// FR-204's "coverage" row fact. `GET /catalog/destinations/{slug}` only
/// returns a single country's own products, which are never regional
/// (API.md §3: `coverage_countries` is non-null only for regional
/// products) -- so every plan on this screen covers exactly the one
/// destination country. Falls back to the real coverage list's length on
/// the off chance a product here ever does carry one.
String planCoverageLabel(Product product) {
  final coverage = product.coverageCountries;
  if (coverage != null && coverage.isNotEmpty) {
    return '${coverage.length} countries';
  }
  return '1 country';
}
