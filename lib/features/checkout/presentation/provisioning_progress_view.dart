import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../application/provisioning_steps.dart';

enum _StepState { done, active, pending }

/// FR-308: the step list shown while an order provisions, Design_System.md
/// §3 list-row pattern. Pure presentation -- driven entirely by [currentStep].
class ProvisioningProgressView extends StatelessWidget {
  const ProvisioningProgressView({super.key, required this.currentStep});

  final ProvisioningStep currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final step in ProvisioningStep.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _StepRow(
              label: provisioningStepLabels[step]!,
              state: step.index < currentStep.index
                  ? _StepState.done
                  : step.index == currentStep.index
                      ? _StepState.active
                      : _StepState.pending,
            ),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final Widget indicator = switch (state) {
      _StepState.done =>
        const Icon(Icons.check_circle, color: AppColors.success, size: 22),
      _StepState.active => const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        ),
      _StepState.pending =>
        const Icon(Icons.circle_outlined, color: AppColors.line, size: 22),
    };
    final textColor =
        state == _StepState.pending ? AppColors.inkMuted : AppColors.ink;
    return Row(
      children: [
        SizedBox(width: 22, height: 22, child: Center(child: indicator)),
        const SizedBox(width: 12),
        Text(label, style: AppTypography.body(color: textColor)),
      ],
    );
  }
}
