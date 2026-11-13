import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/catalog_providers.dart';
import '../application/country_grouping.dart';
import '../data/models/country.dart';

/// FR-202: full-height destination search sheet. The featured "Global"
/// package card needs product-level data (price, country count framing)
/// this screen's plain country list doesn't have -- deferred as FR-202b.
Future<void> showExploreSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ExploreSheet(),
  );
}

class ExploreSheet extends ConsumerStatefulWidget {
  const ExploreSheet({super.key});

  @override
  ConsumerState<ExploreSheet> createState() => _ExploreSheetState();
}

class _ExploreSheetState extends ConsumerState<ExploreSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _regionalTab = false;
  List<Country>? _searchResults;
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      final results =
          await ref.read(catalogApiProvider).getCountries(search: value);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    });
  }

  void _comingSoon(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name plans are coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allCountriesProvider);
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(top: mediaQuery.padding.top + 24),
      child: Container(
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
                  AppSpacing.gutter, 20, AppSpacing.gutter, 12),
              child: SearchPill(
                key: const ValueKey('explore-search'),
                hintText: 'Search countries',
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClose: () => Navigator.of(context).maybePop(),
              ),
            ),
            Flexible(
              child: switch (allAsync) {
                AsyncData(:final value) => _Body(
                    all: value,
                    query: _query,
                    searching: _searching,
                    searchResults: _searchResults,
                    regionalTab: _regionalTab,
                    onRegionalTabChanged: (v) =>
                        setState(() => _regionalTab = v),
                    onCountryTap: _comingSoon,
                  ),
                AsyncError() => Padding(
                    padding: const EdgeInsets.all(32),
                    child: ErrorState(
                      message: "We couldn't load destinations.",
                      onRetry: () => ref.invalidate(allCountriesProvider),
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
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.all,
    required this.query,
    required this.searching,
    required this.searchResults,
    required this.regionalTab,
    required this.onRegionalTabChanged,
    required this.onCountryTap,
  });

  final List<Country> all;
  final String query;
  final bool searching;
  final List<Country>? searchResults;
  final bool regionalTab;
  final ValueChanged<bool> onRegionalTabChanged;
  final ValueChanged<String> onCountryTap;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isNotEmpty) {
      if (searching) {
        return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final results = searchResults ?? const [];
      if (results.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: EmptyState(
            icon: Icons.search_off,
            message: 'No destinations match "$query".',
          ),
        );
      }
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter, vertical: 8),
        children: [
          for (final country in results)
            CountryRow(
              name: country.nameEn,
              flagUrl: country.flagUrl,
              onTap: () => onCountryTap(country.nameEn),
            ),
        ],
      );
    }

    final popular = all.where((c) => c.isPopular).toList();
    final tabEntries =
        regionalTab ? regionalTabEntries(all) : countryTabEntries(all);
    final grouped = groupByFirstLetter(tabEntries);
    final letters = grouped.keys.toList()..sort();

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedPill(
            options: const ['Country', 'Regional'],
            selectedIndex: regionalTab ? 1 : 0,
            onChanged: (i) => onRegionalTabChanged(i == 1),
          ),
        ),
        const SizedBox(height: 16),
        if (!regionalTab && popular.isNotEmpty) ...[
          Text('Popular', style: AppTypography.label()),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: popular.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final country = popular[index];
                return _PopularChip(
                  country: country,
                  onTap: () => onCountryTap(country.nameEn),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        for (final letter in letters) ...[
          Text(letter, style: AppTypography.label(color: AppColors.primary)),
          for (final country in grouped[letter]!)
            CountryRow(
              name: country.nameEn,
              flagUrl: country.flagUrl,
              onTap: () => onCountryTap(country.nameEn),
            ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: AppSpacing.gutter),
      ],
    );
  }
}

class _PopularChip extends StatelessWidget {
  const _PopularChip({required this.country, required this.onTap});

  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.lilac200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlagAvatar(flagUrl: country.flagUrl, size: 22),
            const SizedBox(width: 8),
            Text(country.nameEn, style: AppTypography.label()),
          ],
        ),
      ),
    );
  }
}
