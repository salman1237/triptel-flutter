import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../application/legal_providers.dart';

/// FR-1201: the legal documents list (`GET /settings/legal`). Tapping a
/// row opens its real reader via slug.
class LegalDocumentsScreen extends ConsumerWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(legalDocumentsProvider);

    return TriptelScaffold(
      key: const ValueKey('legal-documents-screen'),
      appBar: AppBar(title: const Text('Legal documents')),
      body: switch (documentsAsync) {
        AsyncData(:final value) => value.isEmpty
            ? const EmptyState(
                icon: Icons.description_outlined,
                message: 'No legal documents are available right now.',
              )
            : ListGroup(
                children: [
                  for (final document in value)
                    ListRow(
                      key: ValueKey('legal-document-row-${document.slug}'),
                      icon: Icons.description_outlined,
                      title: document.title,
                      onTap: () => context.push('/legal/${document.slug}'),
                    ),
                ],
              ),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load legal documents.",
              onRetry: () => ref.invalidate(legalDocumentsProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
