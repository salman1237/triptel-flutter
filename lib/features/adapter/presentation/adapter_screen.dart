import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/ccid_permission_result.dart';
import '../application/ccid_power_on_result.dart';
import '../application/ccid_providers.dart';
import '../application/ccid_reader.dart';

/// FR-L910/FR-L911/FR-L912: lists the USB CCID smart-card reader(s)
/// currently attached (live attach/detach while this screen -- and the
/// app -- is foregrounded), lets the user request the standard
/// per-device USB permission for one that doesn't have it yet, and --
/// once granted -- powers on the card to show the real ATR. No APDU
/// exchange (FR-L913+) happens from this screen yet.
class AdapterScreen extends ConsumerStatefulWidget {
  const AdapterScreen({super.key});

  @override
  ConsumerState<AdapterScreen> createState() => _AdapterScreenState();
}

class _AdapterScreenState extends ConsumerState<AdapterScreen> {
  final Map<int, CcidPowerOnResult> _powerOnResults = {};

  Future<void> _requestPermission(CcidReader reader) async {
    final raw =
        await ref.read(ccidChannelProvider).requestPermission(reader.id);
    final result = parseCcidPermissionResult(raw);
    if (!mounted) return;
    switch (result) {
      case CcidPermissionResult.granted:
        ref.invalidate(ccidReadersProvider);
      case CcidPermissionResult.denied:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Permission denied for this reader -- you can try '
                'again.')));
      case CcidPermissionResult.detachedMeanwhile:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The reader was unplugged before you responded.')));
      case CcidPermissionResult.exception:
      case CcidPermissionResult.unknown:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Couldn't request permission for this reader.")));
    }
  }

  Future<void> _powerOn(CcidReader reader) async {
    final raw = await ref.read(ccidChannelProvider).powerOn(reader.id);
    if (!mounted) return;
    setState(() {
      _powerOnResults[reader.id] = CcidPowerOnResult.fromRaw(raw);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                AsyncData(:final value) => _ReadersList(
                    readers: value,
                    powerOnResults: _powerOnResults,
                    onRequestPermission: _requestPermission,
                    onPowerOn: _powerOn,
                  ),
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
  const _ReadersList({
    required this.readers,
    required this.powerOnResults,
    required this.onRequestPermission,
    required this.onPowerOn,
  });

  final List<CcidReader> readers;
  final Map<int, CcidPowerOnResult> powerOnResults;
  final ValueChanged<CcidReader> onRequestPermission;
  final ValueChanged<CcidReader> onPowerOn;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final reader in readers) ...[
            _ReaderCard(
              reader: reader,
              powerOnResult: powerOnResults[reader.id],
              onRequestPermission: () => onRequestPermission(reader),
              onPowerOn: () => onPowerOn(reader),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
}

class _ReaderCard extends StatelessWidget {
  const _ReaderCard({
    required this.reader,
    required this.powerOnResult,
    required this.onRequestPermission,
    required this.onPowerOn,
  });

  final CcidReader reader;
  final CcidPowerOnResult? powerOnResult;
  final VoidCallback onRequestPermission;
  final VoidCallback onPowerOn;

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
            if (!reader.hasPermission) ...[
              const SizedBox(height: 12),
              PillButton(
                key: ValueKey('adapter-reader-${reader.id}-grant-button'),
                label: 'Grant access',
                variant: PillButtonVariant.secondary,
                onPressed: onRequestPermission,
              ),
            ],
            if (reader.hasPermission) ...[
              const SizedBox(height: 12),
              PillButton(
                key: ValueKey('adapter-reader-${reader.id}-power-on-button'),
                label: 'Power on',
                variant: PillButtonVariant.secondary,
                onPressed: onPowerOn,
              ),
              if (powerOnResult != null) ...[
                const SizedBox(height: 12),
                _PowerOnResultView(
                  key: ValueKey('adapter-reader-${reader.id}-power-on-result'),
                  result: powerOnResult!,
                ),
              ],
            ],
          ],
        ),
      );
}

class _PowerOnResultView extends StatelessWidget {
  const _PowerOnResultView({super.key, required this.result});

  final CcidPowerOnResult result;

  @override
  Widget build(BuildContext context) {
    if (result.outcome == CcidPowerOnOutcome.success) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ATR', style: AppTypography.label()),
          Text(result.atrHex ?? '', style: AppTypography.caption()),
          const SizedBox(height: 4),
          Text(
            'Protocol(s) ${result.protocols.join(', ')} -- using '
            'T=${result.preferredProtocol} · ${result.voltage}',
            style: AppTypography.caption(color: AppColors.inkMuted),
          ),
        ],
      );
    }
    final message = switch (result.outcome) {
      CcidPowerOnOutcome.powerOnFailed =>
        result.reason ?? "Couldn't power on the card.",
      CcidPowerOnOutcome.noPermission =>
        'Access was revoked -- try "Grant access" again.',
      CcidPowerOnOutcome.detached => 'The reader was unplugged.',
      CcidPowerOnOutcome.openFailed => "Couldn't open the reader.",
      CcidPowerOnOutcome.success => '', // unreachable, handled above
      CcidPowerOnOutcome.unknown => "Couldn't power on the card.",
    };
    return Text(message, style: AppTypography.caption(color: AppColors.danger));
  }
}
