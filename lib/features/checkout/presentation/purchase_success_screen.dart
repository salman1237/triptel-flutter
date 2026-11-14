import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../compatibility/application/compatibility_providers.dart';
import '../../compatibility/application/esim_verdict.dart';
import '../application/install_link.dart';
import '../application/url_launcher_provider.dart';
import '../data/models/order.dart';

/// FR-310: QR (FR-401), 1-tap install gated by FR-950, copy the activation
/// code, "Go to My eSIMs". Shown only for a `COMPLETED` order -- FAILED
/// (FR-311) and still-processing (FR-309) stay on the existing SnackBar path
/// in `checkout_review_screen.dart`.
class PurchaseSuccessScreen extends ConsumerWidget {
  const PurchaseSuccessScreen({super.key, required this.order});

  final Order order;

  Future<void> _install(BuildContext context, WidgetRef ref, String url) async {
    final launch = ref.read(urlLauncherProvider);
    final opened = await launch(Uri.parse(url));
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the install link.")));
    }
  }

  Future<void> _copyActivationCode(
      BuildContext context, String lpaString) async {
    await Clipboard.setData(ClipboardData(text: lpaString));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Activation code copied.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esimProfile = order.esimProfile;
    final verdictAsync = ref.watch(esimVerdictProvider);

    return TriptelScaffold(
      key: const ValueKey('purchase-success-screen'),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 56),
            const SizedBox(height: 12),
            Text('Your eSIM is ready!',
                textAlign: TextAlign.center, style: AppTypography.title()),
            const SizedBox(height: 4),
            Text('Order ${order.orderNo}',
                textAlign: TextAlign.center,
                style: AppTypography.label(color: AppColors.inkMuted)),
            const SizedBox(height: 24),
            if (esimProfile != null) ...[
              EsimQr(
                data: esimProfile.qrCodeData.isNotEmpty
                    ? esimProfile.qrCodeData
                    : esimProfile.lpaString,
              ),
              const SizedBox(height: 24),
              verdictAsync.when(
                data: (verdict) => _InstallSection(
                  verdict: verdict,
                  lpaString: esimProfile.lpaString,
                  onInstall: (url) => _install(context, ref, url),
                  onCopy: () =>
                      _copyActivationCode(context, esimProfile.lpaString),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => _InstallSection(
                  verdict: const EsimVerdict(
                    kind: EsimVerdictKind.unknown,
                    deviceLabel: '',
                    reason: '',
                  ),
                  lpaString: esimProfile.lpaString,
                  onInstall: (url) => _install(context, ref, url),
                  onCopy: () =>
                      _copyActivationCode(context, esimProfile.lpaString),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 8),
            PillButton(
              key: const ValueKey('go-to-my-esims-button'),
              label: 'Go to My eSIMs',
              variant: PillButtonVariant.secondary,
              onPressed: () => context.go('/my-esims'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallSection extends StatelessWidget {
  const _InstallSection({
    required this.verdict,
    required this.lpaString,
    required this.onInstall,
    required this.onCopy,
  });

  final EsimVerdict verdict;
  final String lpaString;
  final ValueChanged<String> onInstall;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final installUrl = buildInstallUrl(lpaString, isIOS: Platform.isIOS);

    return Column(
      children: [
        if (installUrl != null && verdict.kind == EsimVerdictKind.supported)
          PillButton(
            key: const ValueKey('one-tap-install-button'),
            label: 'Install eSIM',
            onPressed: () => onInstall(installUrl),
          )
        else if (verdict.kind == EsimVerdictKind.notSupported)
          Text(
            "Your device isn't eSIM-compatible -- your eSIM is saved to "
            'your account for later.',
            textAlign: TextAlign.center,
            style: AppTypography.caption(color: AppColors.inkMuted),
          )
        else
          Text(
            "We couldn't confirm 1-tap install on this device -- use the "
            'activation code below instead.',
            textAlign: TextAlign.center,
            style: AppTypography.caption(color: AppColors.inkMuted),
          ),
        const SizedBox(height: 10),
        PillButton(
          key: const ValueKey('copy-activation-code-button'),
          label: 'Copy activation code',
          variant: PillButtonVariant.text,
          onPressed: onCopy,
        ),
      ],
    );
  }
}
