import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/device_search.dart';
import '../data/models/compatible_device_group.dart';

/// FR-952: curated, searchable eSIM-compatible device list ported from the
/// web `guides/compatible-phones` page, plus the `*#06#` EID check tip and
/// an OS settings-path fallback (Rules.md: device identifiers never
/// requested here, this is a static reference list).
class SupportedDevicesScreen extends StatefulWidget {
  const SupportedDevicesScreen({super.key});

  @override
  State<SupportedDevicesScreen> createState() => _SupportedDevicesScreenState();
}

class _SupportedDevicesScreenState extends State<SupportedDevicesScreen> {
  int _brandIndex = 0;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = compatibleDeviceGroups[_brandIndex].brand;
    final models = filterDeviceModels(
      groups: compatibleDeviceGroups,
      brand: brand,
      query: _query,
    );

    return Scaffold(
      key: const ValueKey('supported-devices-screen'),
      backgroundColor: AppColors.lilac50,
      appBar: AppBar(
        backgroundColor: AppColors.lilac50,
        elevation: 0,
        title: Text('Supported Devices', style: AppTypography.headline()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _EidTipBox(),
              const SizedBox(height: 16),
              const _SettingsPathBox(),
              const SizedBox(height: 20),
              SearchPill(
                hintText: 'Search models',
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedPill(
                  options: [
                    for (final group in compatibleDeviceGroups) group.brand,
                  ],
                  selectedIndex: _brandIndex,
                  onChanged: (index) => setState(() => _brandIndex = index),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: models.isEmpty
                    ? SingleChildScrollView(
                        child: EmptyState(
                          icon: Icons.search_off,
                          message: 'No $brand models match "$_query".',
                        ),
                      )
                    : ListView.separated(
                        itemCount: models.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) => _DeviceRow(
                          model: models[index],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.model});

  final String model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [appCardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(child: Text(model, style: AppTypography.body())),
        ],
      ),
    );
  }
}

class _EidTipBox extends StatelessWidget {
  const _EidTipBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.dialpad, size: 18, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The fastest way to check: dial *#06#',
                    style: AppTypography.label(color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                  "Open your phone's dialer and dial *#06# — if you see a "
                  "line labelled EID, your phone supports eSIM. If there's "
                  'only an IMEI, it cannot use an eSIM.',
                  style: AppTypography.caption(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPathBox extends StatelessWidget {
  const _SettingsPathBox();

  @override
  Widget build(BuildContext context) {
    return const InfoBox(
      text: 'Still not sure? On iPhone: Settings > General > About > look '
          'for "Digital SIM". On Android: Settings > Network & internet > '
          'SIMs > look for "Add eSIM" or "Download a SIM".',
    );
  }
}
