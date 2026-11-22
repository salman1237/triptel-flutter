import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/ccid_permission_result.dart';
import '../application/ccid_power_on_result.dart';
import '../application/ccid_providers.dart';
import '../application/ccid_read_eid_result.dart';
import '../application/ccid_reader.dart';
import '../application/ccid_select_isdr_result.dart';

/// FR-L910/FR-L911/FR-L912/FR-L913: lists the USB CCID smart-card
/// reader(s) currently attached (live attach/detach while this screen
/// -- and the app -- is foregrounded), lets the user request the
/// standard per-device USB permission for one that doesn't have it yet,
/// powers on the card to show the real ATR, and -- once powered on --
/// opens a logical channel and selects ISD-R by AID to show the real
/// status word/FCI. No profile download (FR-L914+/euicc library) from
/// this screen yet.
class AdapterScreen extends ConsumerStatefulWidget {
  const AdapterScreen({super.key});

  @override
  ConsumerState<AdapterScreen> createState() => _AdapterScreenState();
}

class _AdapterScreenState extends ConsumerState<AdapterScreen> {
  final Map<int, CcidPowerOnResult> _powerOnResults = {};
  final Map<int, CcidSelectIsdRResult> _selectIsdRResults = {};
  final Map<int, CcidReadEidResult> _readEidResults = {};
  final Set<int> _eidRevealed = {};

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

  Future<void> _selectIsdR(CcidReader reader) async {
    final raw = await ref.read(ccidChannelProvider).selectIsdR(reader.id);
    if (!mounted) return;
    setState(() {
      _selectIsdRResults[reader.id] = CcidSelectIsdRResult.fromRaw(raw);
    });
  }

  Future<void> _readEid(CcidReader reader) async {
    final raw = await ref.read(ccidChannelProvider).readEid(reader.id);
    if (!mounted) return;
    setState(() {
      _readEidResults[reader.id] = CcidReadEidResult.fromRaw(raw);
    });
  }

  void _toggleEidRevealed(int readerId) {
    setState(() {
      if (!_eidRevealed.add(readerId)) _eidRevealed.remove(readerId);
    });
  }

  Future<void> _copyEid(String eid) async {
    await Clipboard.setData(ClipboardData(text: eid));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('EID copied.')));
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
                    selectIsdRResults: _selectIsdRResults,
                    readEidResults: _readEidResults,
                    eidRevealed: _eidRevealed,
                    onRequestPermission: _requestPermission,
                    onPowerOn: _powerOn,
                    onSelectIsdR: _selectIsdR,
                    onReadEid: _readEid,
                    onToggleEidRevealed: _toggleEidRevealed,
                    onCopyEid: _copyEid,
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
    required this.selectIsdRResults,
    required this.readEidResults,
    required this.eidRevealed,
    required this.onRequestPermission,
    required this.onPowerOn,
    required this.onSelectIsdR,
    required this.onReadEid,
    required this.onToggleEidRevealed,
    required this.onCopyEid,
  });

  final List<CcidReader> readers;
  final Map<int, CcidPowerOnResult> powerOnResults;
  final Map<int, CcidSelectIsdRResult> selectIsdRResults;
  final Map<int, CcidReadEidResult> readEidResults;
  final Set<int> eidRevealed;
  final ValueChanged<CcidReader> onRequestPermission;
  final ValueChanged<CcidReader> onPowerOn;
  final ValueChanged<CcidReader> onSelectIsdR;
  final ValueChanged<CcidReader> onReadEid;
  final ValueChanged<int> onToggleEidRevealed;
  final ValueChanged<String> onCopyEid;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final reader in readers) ...[
            _ReaderCard(
              reader: reader,
              powerOnResult: powerOnResults[reader.id],
              selectIsdRResult: selectIsdRResults[reader.id],
              readEidResult: readEidResults[reader.id],
              eidRevealed: eidRevealed.contains(reader.id),
              onRequestPermission: () => onRequestPermission(reader),
              onPowerOn: () => onPowerOn(reader),
              onSelectIsdR: () => onSelectIsdR(reader),
              onReadEid: () => onReadEid(reader),
              onToggleEidRevealed: () => onToggleEidRevealed(reader.id),
              onCopyEid: onCopyEid,
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
    required this.selectIsdRResult,
    required this.readEidResult,
    required this.eidRevealed,
    required this.onRequestPermission,
    required this.onPowerOn,
    required this.onSelectIsdR,
    required this.onReadEid,
    required this.onToggleEidRevealed,
    required this.onCopyEid,
  });

  final CcidReader reader;
  final CcidPowerOnResult? powerOnResult;
  final CcidSelectIsdRResult? selectIsdRResult;
  final CcidReadEidResult? readEidResult;
  final bool eidRevealed;
  final VoidCallback onRequestPermission;
  final VoidCallback onPowerOn;
  final VoidCallback onSelectIsdR;
  final VoidCallback onReadEid;
  final VoidCallback onToggleEidRevealed;
  final ValueChanged<String> onCopyEid;

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
              if (powerOnResult?.outcome == CcidPowerOnOutcome.success) ...[
                const SizedBox(height: 12),
                PillButton(
                  key: ValueKey(
                      'adapter-reader-${reader.id}-select-isdr-button'),
                  label: 'Select ISD-R',
                  variant: PillButtonVariant.secondary,
                  onPressed: onSelectIsdR,
                ),
                if (selectIsdRResult != null) ...[
                  const SizedBox(height: 12),
                  _SelectIsdRResultView(
                    key: ValueKey(
                        'adapter-reader-${reader.id}-select-isdr-result'),
                    result: selectIsdRResult!,
                  ),
                ],
                const SizedBox(height: 12),
                PillButton(
                  key: ValueKey('adapter-reader-${reader.id}-read-eid-button'),
                  label: 'Read EID',
                  variant: PillButtonVariant.secondary,
                  onPressed: onReadEid,
                ),
                if (readEidResult != null) ...[
                  const SizedBox(height: 12),
                  _ReadEidResultView(
                    key:
                        ValueKey('adapter-reader-${reader.id}-read-eid-result'),
                    result: readEidResult!,
                    revealed: eidRevealed,
                    onToggleRevealed: onToggleEidRevealed,
                    onCopy: onCopyEid,
                  ),
                ],
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

class _SelectIsdRResultView extends StatelessWidget {
  const _SelectIsdRResultView({super.key, required this.result});

  final CcidSelectIsdRResult result;

  @override
  Widget build(BuildContext context) {
    if (result.outcome == CcidSelectIsdROutcome.success) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SW ${result.sw} -- ${result.swIsSuccess == true ? 'OK' : 'not OK'}',
            style: AppTypography.caption(
              color: result.swIsSuccess == true
                  ? AppColors.success
                  : AppColors.danger,
            ),
          ),
          if ((result.fciHex ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('FCI', style: AppTypography.label()),
            Text(result.fciHex!, style: AppTypography.caption()),
          ],
        ],
      );
    }
    final message = switch (result.outcome) {
      CcidSelectIsdROutcome.channelOpenFailed =>
        result.reason ?? "Couldn't open a logical channel.",
      CcidSelectIsdROutcome.selectFailed =>
        result.reason ?? "Couldn't select ISD-R.",
      CcidSelectIsdROutcome.notPoweredOn => 'Power on the card first.',
      CcidSelectIsdROutcome.success => '', // unreachable, handled above
      CcidSelectIsdROutcome.unknown => "Couldn't select ISD-R.",
    };
    return Text(message, style: AppTypography.caption(color: AppColors.danger));
  }
}

class _ReadEidResultView extends StatelessWidget {
  const _ReadEidResultView({
    super.key,
    required this.result,
    required this.revealed,
    required this.onToggleRevealed,
    required this.onCopy,
  });

  final CcidReadEidResult result;
  final bool revealed;
  final VoidCallback onToggleRevealed;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    if (result.outcome == CcidReadEidOutcome.success) {
      final eid = result.eid ?? '';
      // FR-L914/docs/Rules.md: "EID ... stay on the device" and "mask
      // them in UI by default" -- never sent anywhere, shown only on
      // request.
      final display = revealed
          ? eid
          : (eid.length > 4
              ? '${'•' * (eid.length - 4)}${eid.substring(eid.length - 4)}'
              : eid);
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EID', style: AppTypography.label()),
                Text(display, style: AppTypography.caption()),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('adapter-eid-reveal-toggle'),
            icon: Icon(revealed ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggleRevealed,
          ),
          IconButton(
            key: const ValueKey('adapter-eid-copy'),
            icon: const Icon(Icons.copy),
            onPressed: () => onCopy(eid),
          ),
        ],
      );
    }
    final message = switch (result.outcome) {
      CcidReadEidOutcome.readFailed => "Couldn't read the EID.",
      CcidReadEidOutcome.notPoweredOn => 'Power on the card first.',
      CcidReadEidOutcome.success => '', // unreachable, handled above
      CcidReadEidOutcome.unknown => "Couldn't read the EID.",
    };
    return Text(message, style: AppTypography.caption(color: AppColors.danger));
  }
}
