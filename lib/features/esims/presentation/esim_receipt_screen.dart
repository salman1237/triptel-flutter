import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/esim_receipt_shape.dart';
import '../application/esim_status_providers.dart';
import '../application/receipt_sharer.dart';

/// FR-409: a printable/shareable receipt (order no, ICCID, QR, plan) for
/// one eSIM, captured as a PNG via [RepaintBoundary] and shared through
/// the native share sheet -- no new PDF dependency added for this (Rules.md:
/// don't add a dependency unless needed; an image satisfies "printable/
/// shareable" just as well, since the OS share sheet offers Print/Save
/// for an image on both platforms). `price` is listed in the FR's own
/// text but isn't available anywhere on this screen's data source
/// (`GET /esims/{id}/status` carries no price field, API.md section 7) --
/// omitted rather than guessed, a disclosed limitation like others this
/// session.
class EsimReceiptScreen extends ConsumerStatefulWidget {
  const EsimReceiptScreen({super.key, required this.esimId});

  final String esimId;

  @override
  ConsumerState<EsimReceiptScreen> createState() => _EsimReceiptScreenState();
}

class _EsimReceiptScreenState extends ConsumerState<EsimReceiptScreen> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await ref.read(receiptSharerProvider)(_boundaryKey);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(esimStatusProvider(widget.esimId));

    return TriptelScaffold(
      key: const ValueKey('esim-receipt-screen'),
      appBar: AppBar(title: const Text('Receipt')),
      body: switch (statusAsync) {
        AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  key: const ValueKey('esim-receipt-card'),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Triptel',
                          style:
                              AppTypography.headline(color: AppColors.primary)),
                      const SizedBox(height: 16),
                      Text(value.product.title, style: AppTypography.title()),
                      const SizedBox(height: 4),
                      Text(receiptDataLabel(value.product),
                          style: AppTypography.body(color: AppColors.inkMuted)),
                      const SizedBox(height: 20),
                      _ReceiptRow(label: 'Order no.', value: value.orderNo),
                      _ReceiptRow(label: 'ICCID', value: value.iccid),
                      const SizedBox(height: 20),
                      Center(
                        child: EsimQr(
                          data: value.qrCodeData.isNotEmpty
                              ? value.qrCodeData
                              : value.lpaString,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PillButton(
                key: const ValueKey('esim-receipt-share-button'),
                label: _sharing ? 'Preparing...' : 'Share receipt',
                onPressed: _sharing ? null : _share,
              ),
            ],
          ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load this eSIM's receipt.",
              onRetry: () => ref.invalidate(esimStatusProvider(widget.esimId)),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption(color: AppColors.inkMuted)),
          Text(value, style: AppTypography.body()),
        ],
      ),
    );
  }
}
