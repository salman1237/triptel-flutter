import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/compatibility/application/device_search.dart';
import 'package:triptel/features/compatibility/data/models/compatible_device_group.dart';

void main() {
  const groups = [
    CompatibleDeviceGroup(brand: 'Apple', models: ['iPhone 15', 'iPhone 14']),
    CompatibleDeviceGroup(brand: 'Samsung', models: ['Galaxy S24']),
  ];

  test('empty query returns the whole brand group', () {
    final result =
        filterDeviceModels(groups: groups, brand: 'Apple', query: '');
    expect(result, ['iPhone 15', 'iPhone 14']);
  });

  test('query filters within the selected brand, case-insensitive', () {
    final result =
        filterDeviceModels(groups: groups, brand: 'Apple', query: 'IPHONE 15');
    expect(result, ['iPhone 15']);
  });

  test('a query matching nothing returns an empty list', () {
    final result =
        filterDeviceModels(groups: groups, brand: 'Apple', query: 'pixel');
    expect(result, isEmpty);
  });

  test('search is scoped to the selected brand, not other brands', () {
    final result =
        filterDeviceModels(groups: groups, brand: 'Apple', query: 'Galaxy');
    expect(result, isEmpty);
  });

  test('an unknown brand returns an empty list, not a crash', () {
    final result =
        filterDeviceModels(groups: groups, brand: 'Nokia', query: '');
    expect(result, isEmpty);
  });
}
