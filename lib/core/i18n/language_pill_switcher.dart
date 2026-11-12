import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../../features/bootstrap/application/bootstrap_providers.dart';
import 'language_providers.dart';

/// FR-006's language switcher: a header pill (same pattern as FR-005's
/// currency pill) opening a bottom sheet of the backend's active languages.
class LanguagePillSwitcher extends ConsumerWidget {
  const LanguagePillSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languagePreferenceProvider);

    return language.when(
      loading: () => const SizedBox(width: 64, height: 32),
      error: (error, stack) => const SizedBox.shrink(),
      data: (code) => GestureDetector(
        key: const ValueKey('language-pill'),
        onTap: () => _openSheet(context, ref, code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(code.toUpperCase(),
                  style: AppTypography.label(color: AppColors.ink)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref, String selectedCode) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, sheetRef, _) {
          final bootstrap = sheetRef.watch(bootstrapProvider);
          return SafeArea(
            child: bootstrap.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => const SizedBox.shrink(),
              data: (data) => ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Choose language',
                        style: AppTypography.headline()),
                  ),
                  for (final language
                      in data.languages.where((l) => l.isActive))
                    ListTile(
                      key: ValueKey('language-option-${language.code}'),
                      title: Text(
                        '${language.nativeName} (${language.code.toUpperCase()})',
                        style: AppTypography.body(),
                      ),
                      trailing: language.code == selectedCode
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        sheetRef
                            .read(languagePreferenceProvider.notifier)
                            .select(language.code);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
