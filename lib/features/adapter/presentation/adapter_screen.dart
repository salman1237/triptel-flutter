import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/ccid_providers.dart';
import '../application/ccid_reader.dart';

/// FR-L910: lists the USB CCID smart-card reader(s) currently attached
/// (live attach/detach while this screen -- and the app -- is
/// foregrounded). This is detection only: no permission request
/// (FR-L911) or card access (FR-L912+) happens from this screen yet.
class AdapterScreen extends ConsumerWidget {
  const AdapterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUsbHostAsync = ref.watch(ccidHasUsbHostProvider);
    final readersAsync = ref.watch(ccidReadersProvider);

    return TriptelScaffold(
      key: const ValueKey('adapter-screen'),
      appBar: AppBar(title: const Text('eSIM adapter (USB)')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'A removable eSIM adapter plugs into this phone over USB as '
            'a smart-card reader.',
            style: AppTypography.caption(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          switch (hasUsbHostAsync) {
            AsyncData(value: false) => const _UnsupportedState(),
            AsyncData() => switch (readersAsync) {
                AsyncData(:final value) when value.isEmpty =>
                  const _NoReaderState(),
                AsyncData(:final value) => _ReadersList(readers: value),
                AsyncError() => ErrorState(
                    message: "Couldn't check for a reader.",
                    onRetry: () => ref.invalidate(ccidReadersProvider),
                  ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            AsyncError() => ErrorState(
                message: "Couldn't check this device.",
                onRetry: () => ref.invalidate(ccidHasUsbHostProvider),
              ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ],
      ),
    );
  }
}

class _UnsupportedState extends StatelessWidget {
  const _UnsupportedState();

  @override
  Widget build(BuildContext context) => Text(
        key: const ValueKey('adapter-unsupported-state'),
        "This device doesn't support USB host mode, so it can't connect "
        'to a removable eSIM adapter.',
        style: AppTypography.body(color: AppColors.inkMuted),
      );
}

class _NoReaderState extends StatelessWidget {
  const _NoReaderState();

  @override
  Widget build(BuildContext context) => Text(
        key: const ValueKey('adapter-no-reader-state'),
        'No reader connected. Plug a USB eSIM adapter into this phone '
        '(an OTG adapter first, if the reader itself is USB-A).',
        style: AppTypography.body(color: AppColors.inkMuted),
      );
}

class _ReadersList extends StatelessWidget {
  const _ReadersList({required this.readers});

  final List<CcidReader> readers;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final reader in readers) ...[
            _ReaderCard(reader: reader),
            const SizedBox(height: 12),
          ],
        ],
      );
}

class _ReaderCard extends StatelessWidget {
  const _ReaderCard({required this.reader});

  final CcidReader reader;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('adapter-reader-${reader.id}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: reader.hasPermission ? AppColors.success : AppColors.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.usb),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reader.name,
                    style: AppTypography.body()
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vendor ${reader.vendorId} · Product ${reader.productId}',
              style: AppTypography.caption(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 4),
            Text(
              reader.hasPermission ? 'Access granted' : 'Access not granted',
              key: ValueKey('adapter-reader-${reader.id}-permission'),
              style: AppTypography.caption(
                color: reader.hasPermission
                    ? AppColors.success
                    : AppColors.inkMuted,
              ),
            ),
          ],
        ),
      );
}
