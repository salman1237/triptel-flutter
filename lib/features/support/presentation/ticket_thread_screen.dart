import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/support_attachment_opener.dart';
import '../application/support_image_picker.dart';
import '../application/support_providers.dart';
import '../application/ticket_status_chip.dart';
import '../data/models/support_message.dart';
import '../data/models/support_ticket.dart';

const _maxAttachments = 5;

/// FR-1103: a single ticket's thread -- messages (You/Support), each
/// message's attachments downloaded with the real auth header (API.md
/// section 12 -- `GET /support/attachments/{id}`), a reply box with files
/// (hidden once CLOSED), a Close action, and a resolved banner.
class TicketThreadScreen extends ConsumerStatefulWidget {
  const TicketThreadScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<TicketThreadScreen> createState() => _TicketThreadScreenState();
}

class _TicketThreadScreenState extends ConsumerState<TicketThreadScreen> {
  final _replyController = TextEditingController();
  final List<String> _attachmentPaths = [];
  bool _sending = false;
  bool _closing = false;
  String? _error;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _addAttachment() async {
    if (_attachmentPaths.length >= _maxAttachments) return;
    final path = await ref.read(supportImagePickerProvider)();
    if (path != null) setState(() => _attachmentPaths.add(path));
  }

  void _removeAttachment(int index) {
    setState(() => _attachmentPaths.removeAt(index));
  }

  Future<void> _reply() async {
    if (_replyController.text.trim().isEmpty) {
      setState(() => _error = 'Write a reply first.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(supportApiProvider).replyToTicket(
            widget.ticketId,
            body: _replyController.text.trim(),
            filePaths: List.of(_attachmentPaths),
          );
      ref.invalidate(supportTicketsProvider);
      ref.invalidate(supportTicketProvider(widget.ticketId));
      if (!mounted) return;
      _replyController.clear();
      setState(() => _attachmentPaths.clear());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _close() async {
    setState(() => _closing = true);
    try {
      await ref.read(supportApiProvider).closeTicket(widget.ticketId);
      ref.invalidate(supportTicketsProvider);
      ref.invalidate(supportTicketProvider(widget.ticketId));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(supportTicketProvider(widget.ticketId));

    return TriptelScaffold(
      key: const ValueKey('ticket-thread-screen'),
      appBar: AppBar(title: const Text('Ticket')),
      scrollable: false,
      body: switch (ticketAsync) {
        AsyncData(:final value) => _Thread(
            ticket: value,
            replyController: _replyController,
            attachmentPaths: _attachmentPaths,
            sending: _sending,
            closing: _closing,
            error: _error,
            onAddAttachment: _addAttachment,
            onRemoveAttachment: _removeAttachment,
            onReply: _reply,
            onClose: _close,
          ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load this ticket.",
              onRetry: () =>
                  ref.invalidate(supportTicketProvider(widget.ticketId)),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({
    required this.ticket,
    required this.replyController,
    required this.attachmentPaths,
    required this.sending,
    required this.closing,
    required this.error,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
    required this.onReply,
    required this.onClose,
  });

  final SupportTicket ticket;
  final TextEditingController replyController;
  final List<String> attachmentPaths;
  final bool sending;
  final bool closing;
  final String? error;
  final VoidCallback onAddAttachment;
  final void Function(int) onRemoveAttachment;
  final VoidCallback onReply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final chip = ticketStatusChip(ticket.status);
    final messages = ticket.messages ?? const [];
    final isClosed = ticket.status == 'CLOSED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(ticket.subject, style: AppTypography.title()),
              ),
              StatusChip(label: chip.label, tone: chip.tone),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(ticket.reference,
              style: AppTypography.caption(color: AppColors.inkMuted)),
        ),
        if (ticket.status == 'RESOLVED') ...[
          const SizedBox(height: 12),
          Container(
            key: const ValueKey('ticket-resolved-banner'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.smallTag),
            ),
            child: Text(
              'This ticket has been resolved. Reply if you still need help.',
              style: AppTypography.body(color: AppColors.success),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('ticket-thread-messages'),
            itemCount: messages.length,
            itemBuilder: (context, i) => _MessageBubble(message: messages[i]),
          ),
        ),
        if (error != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(error!,
                style: AppTypography.caption(color: AppColors.danger)),
          ),
          const SizedBox(height: 8),
        ],
        if (isClosed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'This ticket is closed. It can no longer be replied to.',
              key: const ValueKey('ticket-closed-notice'),
              style: AppTypography.caption(color: AppColors.inkMuted),
            ),
          )
        else ...[
          for (var i = 0; i < attachmentPaths.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(attachmentPaths[i].split('/').last,
                        style: AppTypography.caption()),
                  ),
                  IconButton(
                    key: ValueKey('ticket-reply-remove-attachment-$i'),
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onRemoveAttachment(i),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('ticket-reply-field'),
                  controller: replyController,
                  decoration: const InputDecoration(hintText: 'Reply...'),
                  minLines: 1,
                  maxLines: 4,
                ),
              ),
              if (attachmentPaths.length < _maxAttachments)
                IconButton(
                  key: const ValueKey('ticket-reply-add-attachment-button'),
                  icon: const Icon(Icons.attach_file),
                  onPressed: onAddAttachment,
                ),
              IconButton(
                key: const ValueKey('ticket-reply-send-button'),
                icon: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: sending ? null : onReply,
              ),
            ],
          ),
          const SizedBox(height: 8),
          PillButton(
            key: const ValueKey('ticket-close-button'),
            label: closing ? 'Closing...' : 'Close ticket',
            variant: PillButtonVariant.secondary,
            onPressed: closing ? null : onClose,
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final align =
        message.isStaff ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    return Padding(
      key: ValueKey('ticket-message-${message.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(message.author,
              style: AppTypography.caption(color: AppColors.inkMuted)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: message.isStaff ? AppColors.surface : AppColors.lilac100,
              borderRadius: BorderRadius.circular(AppRadius.smallTag),
            ),
            child: Text(message.body, style: AppTypography.body()),
          ),
          for (final attachment in message.attachments)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                key: ValueKey('ticket-attachment-${attachment.id}'),
                onTap: () =>
                    ref.read(supportAttachmentOpenerProvider)(attachment),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_file, size: 16),
                    const SizedBox(width: 4),
                    Text(attachment.name, style: AppTypography.caption()),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            DateFormat.yMMMd().add_jm().format(message.createdAt.toLocal()),
            style: AppTypography.caption(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
