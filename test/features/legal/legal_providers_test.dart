import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/legal/application/legal_providers.dart';
import 'package:triptel/features/legal/data/legal_api.dart';
import 'package:triptel/features/legal/data/models/legal_document.dart';

class _FakeLegalApi implements LegalApi {
  _FakeLegalApi({this.error});
  final Object? error;
  String? lastSlug;

  @override
  Future<List<LegalDocument>> getDocuments() async {
    if (error != null) throw error!;
    return const [
      LegalDocument(slug: 'privacy', title: 'Privacy Policy', updatedAt: null),
      LegalDocument(
          slug: 'terms', title: 'Terms & Conditions', updatedAt: null),
    ];
  }

  @override
  Future<LegalDocumentDetail> getDocument(String slug) async {
    lastSlug = slug;
    if (error != null) throw error!;
    return LegalDocumentDetail(
      slug: slug,
      title: 'Privacy Policy',
      body: '## Heading\nBody text.',
      updatedAt: null,
    );
  }
}

void main() {
  test('legalDocumentsProvider returns the real list', () async {
    final fake = _FakeLegalApi();
    final container = ProviderContainer(
      overrides: [legalApiProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final documents = await container.read(legalDocumentsProvider.future);

    expect(documents, hasLength(2));
    expect(documents.first.slug, 'privacy');
  });

  test('legalDocumentsProvider propagates errors as AsyncError', () async {
    final fake = _FakeLegalApi(error: Exception('network down'));
    final container = ProviderContainer(
      overrides: [legalApiProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(legalDocumentsProvider.future),
      throwsException,
    );
  });

  test('legalDocumentProvider passes the slug through and caches by it',
      () async {
    final fake = _FakeLegalApi();
    final container = ProviderContainer(
      overrides: [legalApiProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final document =
        await container.read(legalDocumentProvider('privacy').future);

    expect(fake.lastSlug, 'privacy');
    expect(document.title, 'Privacy Policy');
  });
}
