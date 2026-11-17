import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../../esims/application/esim_usage_shape.dart';
import '../application/tracking_providers.dart';

/// FR-501: public order tracking, `GET /esims/public/{token}` -- no login
/// needed. Routed from `/track/:token` (FR-007's deep link target). Same
/// response shape as the authenticated `/esims/{id}/status` (reuses
/// `EsimStatus` and FR-403's pure usage/validity formatters), minus
/// anything account-gated: no refresh (`POST /refresh` is `auth`), no
/// top-up section, no "Report a problem" (a real support ticket needs an
/// account), no share icon (`share_url` is always null here, API.md
/// section 7) -- and no FR-405 lifecycle banner / FR-406 history section
/// either, kept out deliberately to stay a focused "read-only detail
/// view" rather than re-replicating every authenticated-screen feature for
/// an anonymous viewer. An invalid/unknown token 404s -- shown as an error
/// with Support contacts, same pattern as FR-109's suspended screen.
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.token});

  final String token;

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(publicEsimStatusProvider(token));
    final settings = ref.watch(bootstrapProvider).value?.settings;

    return TriptelScaffold(
      key: const ValueKey('tracking-screen'),
      appBar: AppBar(title: const Text('Track your eSIM')),
      body: switch (statusAsync) {
        AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(value.product.title, style: AppTypography.title()),
              const SizedBox(height: 4),
              Text(value.status.label,
                  style: AppTypography.label(color: AppColors.inkMuted)),
              const SizedBox(height: 24),
              UsageRing(
                fraction: usageFraction(value.usage),
                centerText: usageCenterText(value.usage),
              ),
              const SizedBox(height: 16),
              Text(validityCountdownLabel(value.validity, DateTime.now()),
                  style: AppTypography.body(color: AppColors.inkMuted)),
              const SizedBox(height: 32),
              const Divider(color: AppColors.line),
              const SizedBox(height: 20),
              EsimQr(
                data: value.qrCodeData.isNotEmpty
                    ? value.qrCodeData
                    : value.lpaString,
              ),
              const SizedBox(height: 20),
              _CopyRow(
                label: 'SM-DP+ address',
                value: value.smdpAddress,
                onCopy: () =>
                    _copy(context, 'SM-DP+ address', value.smdpAddress),
              ),
              if (value.matchingId != null)
                _CopyRow(
                  label: 'Matching ID',
                  value: value.matchingId!,
                  onCopy: () =>
                      _copy(context, 'Matching ID', value.matchingId!),
                ),
              _CopyRow(
                label: 'Activation code (LPA)',
                value: value.lpaString,
                onCopy: () =>
                    _copy(context, 'Activation code', value.lpaString),
              ),
            ],
          ),
        AsyncError(:final error) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_off, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  error is ApiException
                      ? error.message
                      : "This tracking link isn't valid.",
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.inkMuted),
                ),
                if (settings != null &&
                    (settings.supportEmail != null ||
                        settings.supportPhone != null)) ...[
                  const SizedBox(height: 20),
                  InfoBox(
                    icon: Icons.support_agent_outlined,
                    text: [
                      if (settings.supportEmail != null) settings.supportEmail!,
                      if (settings.supportPhone != null) settings.supportPhone!,
                    ].join(' · '),
                  ),
                ],
              ],
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.caption(color: AppColors.inkMuted)),
                Text(value,
                    style: AppTypography.body(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('tracking-copy-$label'),
            icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
