import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/legal_providers.dart';
import '../application/markdown_lite.dart';
import '../data/models/legal_document.dart';

/// FR-1201: a single legal document's reader (`GET /settings/legal/
/// {slug}`), rendering its real markdown-lite body.
class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(legalDocumentProvider(slug));

    return TriptelScaffold(
      key: const ValueKey('legal-document-screen'),
      appBar: AppBar(
        title: Text(switch (documentAsync) {
          AsyncData(:final value) => value.title,
          _ => 'Legal document',
        }),
      ),
      body: switch (documentAsync) {
        AsyncData(:final value) => _Body(document: value),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load this document.",
              onRetry: () => ref.invalidate(legalDocumentProvider(slug)),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.document});

  final LegalDocumentDetail document;

  @override
  Widget build(BuildContext context) {
    final blocks = parseMarkdownLiteBlocks(document.body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        if (document.updatedAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Updated ${DateFormat.yMMMd().format(document.updatedAt!.toLocal())}',
              style: AppTypography.caption(color: AppColors.inkMuted),
            ),
          ),
        for (final block in blocks) _Block(block: block),
        const SizedBox(height: AppSpacing.gutter),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.block});

  final MarkdownLiteBlock block;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      MarkdownLiteHeading(:final text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(text, style: AppTypography.headline()),
        ),
      MarkdownLiteParagraph(:final text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _InlineText(text),
        ),
      MarkdownLiteBulletList(:final items) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: AppTypography.body()),
                      Expanded(child: _InlineText(item)),
                    ],
                  ),
                ),
            ],
          ),
        ),
    };
  }
}

class _InlineText extends StatelessWidget {
  const _InlineText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = parseMarkdownLiteInline(text);
    final bodyStyle = AppTypography.body();
    return Text.rich(
      TextSpan(
        style: bodyStyle,
        children: [
          for (final span in spans)
            TextSpan(
              text: span.text,
              style: span.isBold
                  ? bodyStyle.copyWith(fontWeight: FontWeight.w800)
                  : null,
            ),
        ],
      ),
    );
  }
}
