import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/legal/data/models/legal_document.dart';

void main() {
  test(
      'LegalDocument.fromJson parses the real GET /settings/legal list '
      '(API.md section 1)', () {
    final json = jsonDecode(
      File('test/fixtures/legal_documents.json').readAsStringSync(),
    ) as List;

    final documents = json
        .map((j) => LegalDocument.fromJson(j as Map<String, dynamic>))
        .toList();

    expect(documents, hasLength(6));
    expect(documents.first.slug, 'privacy');
    expect(documents.first.title, 'Privacy Policy');
    expect(documents.first.updatedAt, isNull);
  });

  test(
      'LegalDocumentDetail.fromJson parses the real GET /settings/legal/'
      '{slug} response', () {
    final json = jsonDecode(
      File('test/fixtures/legal_document_privacy.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final document = LegalDocumentDetail.fromJson(json);

    expect(document.slug, 'privacy');
    expect(document.title, 'Privacy Policy');
    expect(document.body, contains('## Information we collect'));
    expect(document.updatedAt, isNull);
  });

  test('updated_at parses to a real DateTime when present', () {
    final document = LegalDocument.fromJson(const {
      'slug': 'terms',
      'title': 'Terms & Conditions',
      'updated_at': '2026-11-01T00:00:00+00:00',
    });

    expect(document.updatedAt, DateTime.utc(2026, 11, 1));
  });
}
