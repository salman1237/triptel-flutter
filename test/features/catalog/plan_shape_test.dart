import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/catalog/application/plan_shape.dart';
import 'package:triptel/features/catalog/data/models/product.dart';

Product _fixed({double gb = 1, int days = 7}) => Product(
      id: 'f',
      countryId: 1,
      titleEn: 'Fixed',
      dataAmountGb: gb,
      validityDays: days,
      retailPrice: const Money(100),
      isUnlimited: false,
      isActive: true,
      isFeatured: false,
    );

Product _dayPass({double totalGb = 3.5, int days = 7}) => Product(
      id: 'd',
      countryId: 1,
      titleEn: 'Day pass',
      dataAmountGb: totalGb,
      validityDays: days,
      retailPrice: const Money(100),
      isUnlimited: false,
      isActive: true,
      isFeatured: false,
      supplierPeriodNum: days,
    );

Product _unlimited({int days = 3}) => Product(
      id: 'u',
      countryId: 1,
      titleEn: 'Unlimited',
      dataAmountGb: 0,
      validityDays: days,
      retailPrice: const Money(100),
      isUnlimited: true,
      isActive: true,
      isFeatured: false,
    );

void main() {
  group('planShape', () {
    test('supplier_period_num == null && !is_unlimited -> fixed', () {
      expect(planShape(_fixed()), PlanShape.fixed);
    });

    test('supplier_period_num != null -> dayPass', () {
      expect(planShape(_dayPass()), PlanShape.dayPass);
    });

    test('is_unlimited == true -> unlimited, even with a supplier_period_num',
        () {
      final product = Product(
        id: 'x',
        countryId: 1,
        titleEn: 'x',
        dataAmountGb: 0,
        validityDays: 3,
        retailPrice: const Money(100),
        isUnlimited: true,
        isActive: true,
        isFeatured: false,
        supplierPeriodNum: 3,
      );
      expect(planShape(product), PlanShape.unlimited);
    });
  });

  group('planDataLabel', () {
    test('fixed under 1GB shows MB (API.md: 0.10 -> "100 MB")', () {
      expect(planDataLabel(_fixed(gb: 0.10)), '100 MB');
    });

    test('fixed at or above 1GB shows GB', () {
      expect(planDataLabel(_fixed(gb: 3)), '3 GB');
    });

    test('day pass shows the PER-DAY share, not the total', () {
      // total 3.42 GB over 7 days = 0.488... -> rounds to 0.49 GB/day.
      expect(planDataLabel(_dayPass(totalGb: 3.42, days: 7)), '0.49 GB/day');
    });

    test('unlimited always says Unlimited', () {
      expect(planDataLabel(_unlimited()), 'Unlimited');
    });
  });

  group('groupByShape', () {
    test('buckets products by their detected shape', () {
      final groups =
          groupByShape([_fixed(), _dayPass(), _unlimited(), _fixed(gb: 2)]);

      expect(groups[PlanShape.fixed], hasLength(2));
      expect(groups[PlanShape.dayPass], hasLength(1));
      expect(groups[PlanShape.unlimited], hasLength(1));
    });
  });

  group('planCoverageLabel', () {
    test(
        'a product with no coverage_countries (this screen\'s normal case, '
        'single-country destinations) says "1 country"', () {
      expect(planCoverageLabel(_fixed()), '1 country');
    });

    test('a product that does carry coverage_countries uses its real length',
        () {
      final product = Product(
        id: 'r',
        countryId: 1,
        titleEn: 'Regional',
        dataAmountGb: 1,
        validityDays: 7,
        retailPrice: const Money(100),
        isUnlimited: false,
        isActive: true,
        isFeatured: false,
        coverageCountries: const ['Australia', 'United Kingdom'],
      );
      expect(planCoverageLabel(product), '2 countries');
    });
  });

  group('fixedDataSizes / planValidityDays', () {
    test('fixedDataSizes returns distinct sizes, ascending', () {
      final sizes =
          fixedDataSizes([_fixed(gb: 3), _fixed(gb: 1), _fixed(gb: 1)]);
      expect(sizes, [1, 3]);
    });

    test('planValidityDays returns distinct days, ascending', () {
      final days = planValidityDays(
          [_unlimited(days: 10), _unlimited(days: 3), _unlimited(days: 3)]);
      expect(days, [3, 10]);
    });
  });
}
