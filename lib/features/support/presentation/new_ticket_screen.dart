import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../esims/application/my_esims_providers.dart';
import '../application/support_image_picker.dart';
import '../application/support_providers.dart';

const _maxAttachments = 5;

/// FR-1102: new support ticket -- real category list (`GET /support/
/// categories`, PARTNER hidden), subject, body, an optional "link an
/// eSIM" picker (embeds the order/eSIM info in the body text rather than
/// a real `order_id`, same reasoning as FR-410: `GET /orders/my-esims`
/// has no order UUID to send), and up to 5 image attachments (disclosed
/// limitation: images only, see `support_image_picker.dart`).
class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _category;
  String? _linkedEsimLabel;
  String? _linkedEsimInfo;
  final List<String> _attachmentPaths = [];
  bool _submitting = false;
  String? _error;
  String? _confirmedReference;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickEsim() async {
    final esims = await ref.read(myEsimsProvider.future);
    if (!mounted || esims.isEmpty) return;
    final id = await PaymentMethodSheet.show(
      context,
      [
        for (final esim in esims)
          PaymentMethodOption(
            id: esim.id,
            label: esim.productTitle,
            subtitle: 'Order ${esim.orderNo}',
            icon: Icons.sim_card_outlined,
          ),
      ],
    );
    if (id == null) return;
    final esim = esims.firstWhere((e) => e.id == id);
    setState(() {
      _linkedEsimLabel = '${esim.productTitle} (${esim.orderNo})';
      _linkedEsimInfo =
          'eSIM: ${esim.productTitle} (order ${esim.orderNo}, eSIM id ${esim.id})';
    });
  }

  Future<void> _addAttachment() async {
    if (_attachmentPaths.length >= _maxAttachments) return;
    final path = await ref.read(supportImagePickerProvider)();
    if (path != null) setState(() => _attachmentPaths.add(path));
  }

  void _removeAttachment(int index) {
    setState(() => _attachmentPaths.removeAt(index));
  }

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a subject.');
      return;
    }
    if (_bodyController.text.trim().isEmpty) {
      setState(() => _error = 'Describe your issue.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final body = _linkedEsimInfo != null
          ? '$_linkedEsimInfo\n\n${_bodyController.text.trim()}'
          : _bodyController.text.trim();
      final ticket = await ref.read(supportApiProvider).createTicket(
            subject: _subjectController.text.trim(),
            body: body,
            category: _category ?? 'OTHER',
            filePaths: _attachmentPaths,
          );
      if (!mounted) return;
      setState(() => _confirmedReference = ticket.reference);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reference = _confirmedReference;
    final categoriesAsync = ref.watch(supportCategoriesProvider);

    return TriptelScaffold(
      key: const ValueKey('new-ticket-screen'),
      appBar: AppBar(title: const Text('New ticket')),
      body: reference != null
          ? _Confirmation(reference: reference)
          : switch (categoriesAsync) {
              AsyncData(:final value) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('new-ticket-category-dropdown'),
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final category in value)
                          DropdownMenuItem(
                            value: category.value,
                            child: Text(category.label),
                          ),
                      ],
                      onChanged: (v) => setState(() => _category = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('new-ticket-subject'),
                      controller: _subjectController,
                      decoration: const InputDecoration(labelText: 'Subject'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('new-ticket-body'),
                      controller: _bodyController,
                      maxLength: 5000,
                      maxLines: 5,
                      decoration: const InputDecoration(
                          labelText: 'Describe the issue'),
                    ),
                    const SizedBox(height: 8),
                    PillButton(
                      key: const ValueKey('new-ticket-link-esim-button'),
                      label: _linkedEsimLabel ?? 'Link an eSIM (optional)',
                      variant: PillButtonVariant.secondary,
                      onPressed: _pickEsim,
                    ),
                    const SizedBox(height: 16),
                    Text(
                        'Attachments (${_attachmentPaths.length}/$_maxAttachments)',
                        style:
                            AppTypography.caption(color: AppColors.inkMuted)),
                    for (var i = 0; i < _attachmentPaths.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(_attachmentPaths[i].split('/').last,
                                  style: AppTypography.body()),
                            ),
                            IconButton(
                              key: ValueKey('new-ticket-remove-attachment-$i'),
                              icon: const Icon(Icons.close),
                              onPressed: () => _removeAttachment(i),
                            ),
                          ],
                        ),
                      ),
                    if (_attachmentPaths.length < _maxAttachments) ...[
                      const SizedBox(height: 4),
                      PillButton(
                        key: const ValueKey('new-ticket-add-attachment-button'),
                        label: 'Add photo',
                        variant: PillButtonVariant.text,
                        fullWidth: false,
                        onPressed: _addAttachment,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!,
                          style:
                              AppTypography.caption(color: AppColors.danger)),
                    ],
                    const SizedBox(height: 20),
                    PillButton(
                      key: const ValueKey('new-ticket-submit-button'),
                      label: _submitting ? 'Submitting...' : 'Submit',
                      onPressed: _submitting ? null : _submit,
                    ),
                  ],
                ),
              AsyncError() => Center(
                  child: ErrorState(
                    message: "We couldn't load support categories.",
                    onRetry: () => ref.invalidate(supportCategoriesProvider),
                  ),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 48),
          const SizedBox(height: 16),
          Text('Ticket $reference created', style: AppTypography.title()),
          const SizedBox(height: 8),
          Text("We'll reply here and by email.",
              style: AppTypography.body(color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
