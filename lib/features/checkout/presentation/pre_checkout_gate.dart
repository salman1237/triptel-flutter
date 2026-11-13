import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../compatibility/application/compatibility_providers.dart';
import '../../compatibility/application/esim_verdict.dart';
import '../application/compatibility_gate.dart';

/// FR-301: run the FR-950 compatibility check before letting a purchase
/// through. Never hard-blocks -- every branch ends by calling [onContinue]
/// unless the user explicitly cancels. A verdict-check failure (e.g. the
/// platform channel threw) also proceeds rather than blocking (Rules.md:
/// compatibility detection never blocks a purchase).
Future<void> runPreCheckoutCompatibilityGate(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback onContinue,
}) async {
  final EsimVerdictKind kind;
  try {
    kind = (await ref.read(esimVerdictProvider.future)).kind;
  } catch (_) {
    onContinue();
    return;
  }
  if (!context.mounted) return;

  switch (decideGateAction(kind)) {
    case GateAction.proceed:
      onContinue();
    case GateAction.showNotSupportedDialog:
      await _showBuyNowUseLaterDialog(context, onContinue: onContinue);
    case GateAction.showUnknownNote:
      await _showUnknownCompatibilityNote(context, onContinue: onContinue);
  }
}

Future<void> _showBuyNowUseLaterDialog(
  BuildContext context, {
  required VoidCallback onContinue,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _GateDialog(
      key: const ValueKey('buy-now-use-later-dialog'),
      icon: Icons.error_outline,
      iconColor: AppColors.warning,
      title: 'Buy Now, Use Later!',
      subtitle: 'Activate anytime.',
      body: "Your device is not eSIM-compatible, but don't worry! Your "
          'eSIM will be stored in your Triptel account.\n\n'
          'You can use your data later when you have an eSIM device.',
      primaryLabel: 'Continue',
      onPrimary: () {
        Navigator.of(dialogContext).pop();
        onContinue();
      },
      secondaryLabel: 'View Supported Devices',
      onSecondary: () {
        Navigator.of(dialogContext).pop();
        context.push('/compatibility/devices');
      },
      onCancel: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

Future<void> _showUnknownCompatibilityNote(
  BuildContext context, {
  required VoidCallback onContinue,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _GateDialog(
      key: const ValueKey('unknown-compatibility-dialog'),
      icon: Icons.help_outline,
      iconColor: AppColors.warning,
      title: "We couldn't confirm eSIM support",
      subtitle: null,
      body: "We couldn't confirm whether this device supports eSIM. You can "
          'check Settings > Cellular for an "Add eSIM" option, or continue '
          "anyway -- your eSIM is stored in your account either way.",
      primaryLabel: 'Continue',
      onPrimary: () {
        Navigator.of(dialogContext).pop();
        onContinue();
      },
      secondaryLabel: null,
      onSecondary: null,
      onCancel: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class _GateDialog extends StatelessWidget {
  const _GateDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.onCancel,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center, style: AppTypography.headline()),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.label(color: AppColors.inkMuted)),
            ],
            const SizedBox(height: 12),
            Text(body,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: AppColors.inkMuted)),
            const SizedBox(height: 20),
            PillButton(
              key: const ValueKey('gate-dialog-primary'),
              label: primaryLabel,
              onPressed: onPrimary,
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 10),
              PillButton(
                key: const ValueKey('gate-dialog-secondary'),
                label: secondaryLabel!,
                variant: PillButtonVariant.secondary,
                onPressed: onSecondary,
              ),
            ],
            const SizedBox(height: 10),
            PillButton(
              key: const ValueKey('gate-dialog-cancel'),
              label: 'Cancel',
              variant: PillButtonVariant.text,
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}
