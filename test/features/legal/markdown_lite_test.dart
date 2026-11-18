import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/legal/application/markdown_lite.dart';

void main() {
  group('parseMarkdownLiteBlocks', () {
    test('parses a heading', () {
      final blocks = parseMarkdownLiteBlocks('## Information we collect');

      expect(blocks, [const MarkdownLiteHeading('Information we collect')]);
    });

    test('parses consecutive bullet lines into one list block', () {
      final blocks = parseMarkdownLiteBlocks('- First\n- Second\n- Third');

      expect(blocks, [
        const MarkdownLiteBulletList(['First', 'Second', 'Third']),
      ]);
    });

    test('a blank line separates two paragraphs', () {
      final blocks = parseMarkdownLiteBlocks('First paragraph.\n\n'
          'Second paragraph.');

      expect(blocks, [
        const MarkdownLiteParagraph('First paragraph.'),
        const MarkdownLiteParagraph('Second paragraph.'),
      ]);
    });

    test('heading, bullets, and a paragraph in sequence', () {
      final blocks = parseMarkdownLiteBlocks(
          '## Heading\n- One\n- Two\n\nA paragraph after the list.');

      expect(blocks, [
        const MarkdownLiteHeading('Heading'),
        const MarkdownLiteBulletList(['One', 'Two']),
        const MarkdownLiteParagraph('A paragraph after the list.'),
      ]);
    });

    test(
        'the real beta Privacy Policy body parses into the expected '
        'block shape (API.md section 1)', () {
      final body = (jsonDecode(
        File('test/fixtures/legal_document_privacy.json').readAsStringSync(),
      ) as Map<String, dynamic>)['body'] as String;

      final blocks = parseMarkdownLiteBlocks(body);

      expect(blocks.whereType<MarkdownLiteHeading>().map((h) => h.text), [
        'Information we collect',
        'How we use it',
        'Who we share it with',
        'Retention',
        'Your rights',
        'Cookies and local storage',
        'Changes',
        'Contact',
      ]);
      expect(blocks.whereType<MarkdownLiteBulletList>(), isNotEmpty);
      expect(blocks.whereType<MarkdownLiteParagraph>(), isNotEmpty);
    });
  });

  group('parseMarkdownLiteInline', () {
    test('plain text with no bold stays a single plain span', () {
      final spans = parseMarkdownLiteInline('No bold here.');

      expect(spans, [
        const MarkdownLiteSpan('No bold here.', isBold: false),
      ]);
    });

    test('a bold span in the middle splits into three spans', () {
      final spans = parseMarkdownLiteInline('Before **bold** after.');

      expect(spans, [
        const MarkdownLiteSpan('Before ', isBold: false),
        const MarkdownLiteSpan('bold', isBold: true),
        const MarkdownLiteSpan(' after.', isBold: false),
      ]);
    });

    test('a real bold bullet from the beta fixture parses correctly', () {
      final spans = parseMarkdownLiteInline(
          '**Account details:** name, username, email address, phone '
          'number and password (stored only as a secure hash).');

      expect(spans.first,
          const MarkdownLiteSpan('Account details:', isBold: true));
      expect(spans.last.isBold, isFalse);
    });
  });
}
