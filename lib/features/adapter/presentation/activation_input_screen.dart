import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/activation_code.dart';
import '../application/clipboard_reader.dart';
import '../application/gallery_qr_decoder.dart';
import '../application/scanner_builder.dart';

/// FR-L902: one screen, four sources feeding FR-L901's parser -- live QR
/// camera scan, decode a QR from a gallery image, paste from clipboard,
/// and a manual form (SM-DP+ address, matching ID, optional
/// confirmation-code requirement). Shows a parsed, masked preview or a
/// plain-language error; never throws on bad input.
class ActivationInputScreen extends ConsumerStatefulWidget {
  const ActivationInputScreen({super.key});

  @override
  ConsumerState<ActivationInputScreen> createState() =>
      _ActivationInputScreenState();
}

class _ActivationInputScreenState extends ConsumerState<ActivationInputScreen> {
  final _smdpController = TextEditingController();
  final _matchingIdController = TextEditingController();
  bool _confirmationRequired = false;
  ActivationCodeResult? _result;
  bool _cameraError = false;

  @override
  void dispose() {
    _smdpController.dispose();
    _matchingIdController.dispose();
    super.dispose();
  }

  void _applyCode(String raw) {
    setState(() {
      _result = parseActivationCode(raw);
      _cameraError = false;
    });
  }

  Future<void> _scanGallery() async {
    final raw = await ref.read(galleryQrDecoderProvider)();
    if (raw == null) return;
    _applyCode(raw);
  }

  Future<void> _pasteFromClipboard() async {
    final text = await ref.read(clipboardReaderProvider)();
    if (!mounted) return;
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Clipboard is empty.')));
      return;
    }
    _applyCode(text);
  }

  void _submitManualForm() {
    final address = _smdpController.text.trim();
    setState(() {
      _result = address.isEmpty
          ? const ActivationCodeInvalid(ActivationCodeError.missingSmdpAddress)
          : ActivationCodeParsed(ActivationCode(
              smdpAddress: address,
              matchingId: _matchingIdController.text.trim(),
              confirmationCodeRequired: _confirmationRequired,
            ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scannerBuilder = ref.watch(scannerBuilderProvider);
    final result = _result;

    return TriptelScaffold(
      key: const ValueKey('activation-input-screen'),
      appBar: AppBar(title: const Text('Add activation code')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text('Scan a QR code', style: AppTypography.headline()),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: scannerBuilder(
                _applyCode,
                () => setState(() => _cameraError = true),
              ),
            ),
          ),
          if (_cameraError) ...[
            const SizedBox(height: 8),
            Text(
              "Couldn't use the camera (permission denied or "
              'unavailable) -- use one of the options below instead.',
              key: const ValueKey('activation-input-camera-error'),
              style: AppTypography.caption(color: AppColors.inkMuted),
            ),
          ],
          const SizedBox(height: 20),
          PillButton(
            key: const ValueKey('activation-input-gallery-button'),
            label: 'Scan a QR from a photo',
            variant: PillButtonVariant.secondary,
            onPressed: _scanGallery,
          ),
          const SizedBox(height: 12),
          PillButton(
            key: const ValueKey('activation-input-paste-button'),
            label: 'Paste from clipboard',
            variant: PillButtonVariant.secondary,
            onPressed: _pasteFromClipboard,
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.line),
          const SizedBox(height: 16),
          Text('Or enter it manually', style: AppTypography.headline()),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('activation-input-smdp-field'),
            controller: _smdpController,
            decoration: const InputDecoration(labelText: 'SM-DP+ address'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('activation-input-matching-id-field'),
            controller: _matchingIdController,
            decoration: const InputDecoration(labelText: 'Matching ID'),
          ),
          CheckboxListTile(
            key: const ValueKey(
                'activation-input-confirmation-required-checkbox'),
            value: _confirmationRequired,
            onChanged: (v) =>
                setState(() => _confirmationRequired = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('A confirmation code will be required'),
          ),
          const SizedBox(height: 8),
          PillButton(
            key: const ValueKey('activation-input-manual-submit-button'),
            label: 'Use this code',
            onPressed: _submitManualForm,
          ),
          const SizedBox(height: 24),
          if (result is ActivationCodeParsed)
            Container(
              key: const ValueKey('activation-input-preview'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.success),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.code.maskedLabel(),
                    style: AppTypography.body()
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (result.code.confirmationCodeRequired) ...[
                    const SizedBox(height: 8),
                    Text(
                      'A confirmation code will be required.',
                      style: AppTypography.caption(color: AppColors.inkMuted),
                    ),
                  ],
                ],
              ),
            )
          else if (result is ActivationCodeInvalid)
            Text(
              _errorMessage(result.error),
              key: const ValueKey('activation-input-error'),
              style: AppTypography.caption(color: AppColors.danger),
            ),
        ],
      ),
    );
  }
}

String _errorMessage(ActivationCodeError error) => switch (error) {
      ActivationCodeError.wrongPrefix =>
        "That doesn't look like an eSIM activation code (should start "
            'with LPA:).',
      ActivationCodeError.unsupportedVersion =>
        'Unsupported activation code version.',
      ActivationCodeError.tooFewFields => 'This activation code is incomplete.',
      ActivationCodeError.missingSmdpAddress => 'Enter the SM-DP+ address.',
      ActivationCodeError.tooManyFields =>
        'This activation code has too many fields.',
      ActivationCodeError.invalidConfirmationCodeFlag =>
        'This activation code has an invalid confirmation-code flag.',
    };
