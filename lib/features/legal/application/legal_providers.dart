import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/legal_api.dart';
import '../data/models/legal_document.dart';

final legalApiProvider =
    Provider<LegalApi>((ref) => LegalApiImpl(ref.watch(apiClientProvider)));

/// FR-1201: the legal documents list, cached for the app session.
final legalDocumentsProvider = FutureProvider<List<LegalDocument>>((ref) {
  return ref.watch(legalApiProvider).getDocuments();
});

/// FR-1201: a single document's full body, keyed by slug.
final legalDocumentProvider =
    FutureProvider.family<LegalDocumentDetail, String>((ref, slug) {
  return ref.watch(legalApiProvider).getDocument(slug);
});
