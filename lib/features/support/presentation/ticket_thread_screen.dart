import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../support_chat/application/support_chat_providers.dart';
import '../../support_chat/data/support_socket.dart';
import '../application/support_attachment_opener.dart';
import '../application/support_image_picker.dart';
import '../application/support_providers.dart';
import '../application/ticket_status_chip.dart';
import '../data/models/support_message.dart';
import '../data/models/support_ticket.dart';

const _maxAttachments = 5;

/// How long after the last `typing` event the indicator clears, if no
/// further one arrives (API.md section 12: "the recipient clears its own
/// typing indicator ~3s after the last one arrives" -- matches web).
const _typingClearDelay = Duration(seconds: 3);

/// Throttle for this side's own outbound typing pings while the reply
/// field is being edited -- avoids a frame on every keystroke.
const _typingSendThrottle = Duration(seconds: 2);

/// FR-1103/FR-C902: a single ticket's thread -- messages (You/Support)
/// with avatars, each message's attachments downloaded with the real auth
/// header (API.md section 12 -- `GET /support/attachments/{id}`), a reply
/// box with files (hidden once CLOSED), a Close action, a resolved
/// banner, and -- live, via `SupportSocket` -- new messages and a "Support
/// is typing" indicator without polling. Replaces the FR-1101-1103
/// REST-only version with the now-live chat contract (same `SupportTicket`/
/// `SupportMessage` backend, not a new system -- Functional_Requirements.md
/// section O).
class TicketThreadScreen extends ConsumerStatefulWidget {
  const TicketThreadScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<TicketThreadScreen> createState() => _TicketThreadScreenState();
}

class _TicketThreadScreenState extends ConsumerState<TicketThreadScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  final List<String> _attachmentPaths = [];
  final List<SupportMessage> _liveMessages = [];
  bool _sending = false;
  bool _closing = false;
  String? _error;
  bool _staffTyping = false;
  Timer? _typingClearTimer;
  DateTime? _lastTypingSentAt;
  StreamSubscription<SupportSocketEvent>? _socketSub;

  @override
  void initState() {
    super.initState();
    final socket = ref.read(supportSocketProvider(widget.ticketId));
    _socketSub = socket.events.listen(_onSocketEvent);
    _replyController.addListener(_onReplyTextChanged);
  }

  void _onSocketEvent(SupportSocketEvent event) {
    if (!mounted) return;
    switch (event) {
      case SupportSocketMessage(message: final message):
        setState(() {
          if (!_liveMessages.any((m) => m.id == message.id)) {
            _liveMessages.add(message);
          }
        });
        _scrollToBottom();
      case SupportSocketTyping(from: 'staff'):
        setState(() => _staffTyping = true);
        _typingClearTimer?.cancel();
        _typingClearTimer = Timer(_typingClearDelay, () {
          if (mounted) setState(() => _staffTyping = false);
        });
      case SupportSocketTyping():
        break; // this app is customer-only; a non-staff sender never occurs
      case SupportSocketReconnected():
        // The socket is never the only source of truth (API.md section
        // 12) -- re-fetch to catch anything sent while disconnected.
        ref.invalidate(supportTicketProvider(widget.ticketId));
      case SupportSocketStatusChanged():
        break; // no connection-status UI for this FR
    }
  }

  void _onReplyTextChanged() {
    final now = DateTime.now();
    if (_lastTypingSentAt != null &&
        now.difference(_lastTypingSentAt!) < _typingSendThrottle) {
      return;
    }
    _lastTypingSentAt = now;
    ref.read(supportSocketProvider(widget.ticketId)).sendTyping();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _typingClearTimer?.cancel();
    _replyController.removeListener(_onReplyTextChanged);
    _replyController.dispose();
    _scrollController.dispose();
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
    // Keeps the autoDispose socket alive (and connected) for as long as
    // this screen is on-screen; torn down automatically once it isn't.
    ref.watch(supportSocketProvider(widget.ticketId));

    return TriptelScaffold(
      key: const ValueKey('ticket-thread-screen'),
      appBar: AppBar(title: const Text('Ticket')),
      scrollable: false,
      body: switch (ticketAsync) {
        AsyncData(:final value) => _Thread(
            ticket: value,
            liveMessages: _liveMessages,
            staffTyping: _staffTyping,
            scrollController: _scrollController,
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
    required this.liveMessages,
    required this.staffTyping,
    required this.scrollController,
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
  final List<SupportMessage> liveMessages;
  final bool staffTyping;
  final ScrollController scrollController;
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
    // `liveMessages` carries anything the socket delivered that a REST
    // fetch hasn't caught up with yet (including this device's own
    // just-sent message, which the ticket channel echoes back -- API.md
    // section 12); dedupe by id once the REST list catches up with it.
    final restMessages = ticket.messages ?? const <SupportMessage>[];
    final restIds = restMessages.map((m) => m.id).toSet();
    final messages = [
      ...restMessages,
      ...liveMessages.where((m) => !restIds.contains(m.id)),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
            controller: scrollController,
            itemCount: messages.length,
            itemBuilder: (context, i) => _MessageBubble(message: messages[i]),
          ),
        ),
        if (staffTyping)
          Padding(
            key: const ValueKey('ticket-staff-typing'),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Support is typing',
                    style: AppTypography.caption(color: AppColors.inkMuted)),
                const SizedBox(width: 4),
                const _TypingDots(),
              ],
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

/// FR-C902: a small bounce-dot "typing" indicator, matching web's
/// (never persisted -- API.md section 12).
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Opacity(
                  opacity: 0.3 +
                      0.7 *
                          (((_controller.value * 3 - i) % 3).clamp(0, 1) < 0.5
                              ? 1
                              : 0.2),
                  child: const Icon(Icons.circle,
                      size: 5, color: AppColors.inkMuted),
                ),
              ),
          ],
        );
      },
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
    final fallbackIcon = Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
          color: AppColors.lilac100, shape: BoxShape.circle),
      child: Icon(
        message.isStaff ? Icons.support_agent : Icons.person,
        size: 16,
        color: AppColors.primary,
      ),
    );
    // Same pattern as `FlagAvatar` -- a broken/unreachable avatar URL
    // falls back to the icon rather than surfacing a raw image error.
    final avatar = KeyedSubtree(
      key: const ValueKey('ticket-message-avatar'),
      child: message.authorAvatarUrl == null
          ? fallbackIcon
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: message.authorAvatarUrl!,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallbackIcon,
                errorWidget: (_, __, ___) => fallbackIcon,
              ),
            ),
    );
    return Padding(
      key: ValueKey('ticket-message-${message.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: message.isStaff
                ? [
                    avatar,
                    const SizedBox(width: 6),
                    Text(message.author,
                        style:
                            AppTypography.caption(color: AppColors.inkMuted)),
                  ]
                : [
                    Text(message.author,
                        style:
                            AppTypography.caption(color: AppColors.inkMuted)),
                    const SizedBox(width: 6),
                    avatar,
                  ],
          ),
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
