import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/kyc_image_picker.dart';
import '../application/kyc_providers.dart';
import '../application/kyc_status_label.dart';
import '../data/models/kyc_status.dart';

/// FR-1003: KYC status (read, already surfaced on FR-1001's Account row
/// too) + submission (NID number + front photo required + back photo
/// optional, `POST /kyc/submit` multipart). Resubmitting resets the
/// status to PENDING server-side (API.md §11), so the form stays
/// available for REJECTED/PENDING; APPROVED shows a plain success state
/// instead (nothing left to submit).
class KycScreen extends ConsumerWidget {
  const KycScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(kycStatusProvider);

    return TriptelScaffold(
      key: const ValueKey('kyc-screen'),
      appBar: AppBar(title: const Text('Identity verification')),
      body: switch (statusAsync) {
        AsyncData(:final value) => value.submitted && value.status == 'APPROVED'
            ? const Center(
                child: EmptyState(
                  icon: Icons.verified_outlined,
                  message: 'Your identity is verified.',
                ),
              )
            : _KycForm(status: value),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load your identity verification status.",
              onRetry: () => ref.invalidate(kycStatusProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _KycForm extends ConsumerStatefulWidget {
  const _KycForm({required this.status});

  final KycStatus status;

  @override
  ConsumerState<_KycForm> createState() => _KycFormState();
}

class _KycFormState extends ConsumerState<_KycForm> {
  final _nidController = TextEditingController();
  String? _frontPath;
  String? _backPath;
  bool _submitting = false;

  @override
  void dispose() {
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _pickFront() async {
    final path = await ref.read(kycImagePickerProvider)();
    if (path != null) setState(() => _frontPath = path);
  }

  Future<void> _pickBack() async {
    final path = await ref.read(kycImagePickerProvider)();
    if (path != null) setState(() => _backPath = path);
  }

  Future<void> _submit() async {
    if (_nidController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter your NID number.')));
      return;
    }
    if (_frontPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a front photo of your NID.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(kycApiProvider).submit(
            nidNumber: _nidController.text.trim(),
            documentFrontPath: _frontPath!,
            documentBackPath: _backPath,
          );
      if (!mounted) return;
      ref.invalidate(kycStatusProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Submitted for review.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final chip = kycStatusLabel(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(chip.label,
            key: const ValueKey('kyc-status-label'),
            style: AppTypography.title(color: chip.color)),
        if (status.status == 'REJECTED' && status.rejectionReason != null) ...[
          const SizedBox(height: 4),
          Text(status.rejectionReason!,
              key: const ValueKey('kyc-rejection-reason'),
              style: AppTypography.caption(color: AppColors.danger)),
        ],
        if (status.submittedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Submitted ${DateFormat.yMMMd().format(status.submittedAt!.toLocal())}',
            style: AppTypography.caption(color: AppColors.inkMuted),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('kyc-nid-field'),
          controller: _nidController,
          decoration: const InputDecoration(labelText: 'NID number'),
        ),
        const SizedBox(height: 12),
        PillButton(
          key: const ValueKey('kyc-front-photo-button'),
          label: _frontPath == null ? 'Add front photo' : 'Front photo added',
          variant: PillButtonVariant.secondary,
          onPressed: _pickFront,
        ),
        const SizedBox(height: 8),
        PillButton(
          key: const ValueKey('kyc-back-photo-button'),
          label: _backPath == null
              ? 'Add back photo (optional)'
              : 'Back photo added',
          variant: PillButtonVariant.secondary,
          onPressed: _pickBack,
        ),
        const SizedBox(height: 16),
        PillButton(
          key: const ValueKey('kyc-submit-button'),
          label: _submitting ? 'Submitting...' : 'Submit for review',
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
