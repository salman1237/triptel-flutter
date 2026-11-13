import '../data/models/compatible_device_group.dart';

/// FR-952's filter logic, kept pure/testable (Architecture.md: business
/// rules in plain Dart). Search is scoped to the selected brand's models.
List<String> filterDeviceModels({
  required List<CompatibleDeviceGroup> groups,
  required String brand,
  required String query,
}) {
  final group = groups.firstWhere(
    (g) => g.brand == brand,
    orElse: () => const CompatibleDeviceGroup(brand: '', models: []),
  );
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return group.models;
  return group.models
      .where((model) => model.toLowerCase().contains(trimmed))
      .toList();
}
