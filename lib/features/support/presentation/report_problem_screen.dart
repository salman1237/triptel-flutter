import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/support_providers.dart';

/// FR-410: "Report a problem" for one eSIM -- opens a new support ticket
/// prefilled with category `ESIM` and the order it's about. The real
/// `order_id` foreign key `POST /support/tickets` expects isn't available
/// on the eSIM detail screen's data path (only `esimId`/`orderNo` are,
/// API.md section 7) -- rather than guess a value that would fail the
/// backend's foreign-key constraint, the order is identified in the
/// ticket's own subject/body text instead, which support staff can read.
/// Category is fixed, not a picker -- FR-410 names exactly one category
/// for this entry point; the general "new ticket" flow with a real
/// category picker is FR-1102, not built yet.
class ReportProblemArgs {
  const ReportProblemArgs({
    required this.esimId,
    required this.orderNo,
    required this.planTitle,
  });

  final String esimId;
  final String orderNo;
  final String planTitle;
}

class ReportProblemScreen extends ConsumerStatefulWidget {
  const ReportProblemScreen({super.key, required this.args});

  final ReportProblemArgs args;

  @override
  ConsumerState<ReportProblemScreen> createState() =>
      _ReportProblemScreenState();
}

class _ReportProblemScreenState extends ConsumerState<ReportProblemScreen> {
  late final _subjectController =
      TextEditingController(text: 'Problem with eSIM ${widget.args.orderNo}');
  final _bodyController = TextEditingController();

  bool _submitting = false;
  String? _error;
  String? _confirmedReference;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_bodyController.text.trim().isEmpty) {
      setState(() => _error = 'Describe the problem before submitting.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final body =
          'eSIM: ${widget.args.planTitle} (order ${widget.args.orderNo}, '
          'eSIM id ${widget.args.esimId})\n\n${_bodyController.text.trim()}';
      final ticket = await ref.read(supportApiProvider).createTicket(
            subject: _subjectController.text.trim(),
            body: body,
            category: 'ESIM',
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
    return TriptelScaffold(
      key: const ValueKey('report-problem-screen'),
      appBar: AppBar(title: const Text('Report a problem')),
      body: reference != null
          ? _Confirmation(reference: reference)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(widget.args.planTitle, style: AppTypography.title()),
                const SizedBox(height: 4),
                Text('Order ${widget.args.orderNo}',
                    style: AppTypography.caption(color: AppColors.inkMuted)),
                const SizedBox(height: 20),
                TextField(
                  key: const ValueKey('report-problem-subject'),
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('report-problem-body'),
                  controller: _bodyController,
                  decoration:
                      const InputDecoration(labelText: 'What went wrong?'),
                  maxLines: 5,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: AppTypography.caption(color: AppColors.danger)),
                ],
                const SizedBox(height: 20),
                PillButton(
                  key: const ValueKey('report-problem-submit'),
                  label: _submitting ? 'Submitting...' : 'Submit',
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
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
