/// FR-1201: a tiny, dependency-free renderer for the backend's own
/// "markdown-lite" (API.md section 1: `GET /settings/legal/{slug}`'s
/// `body` is "admin-edited markdown-lite"). Real captured bodies (beta
/// Privacy Policy/Terms, see test/fixtures/legal_document_privacy.json)
/// only ever use `## Heading`, `- bullet` lines, `**bold**` spans, and
/// blank-line-separated paragraphs -- no links, images, tables, nested
/// lists, or other headings levels. A real markdown package would be
/// a dependency for features this content never actually uses (Rules.md:
/// add a dependency only when needed); this is documented in
/// DECISIONS.md.
sealed class MarkdownLiteBlock {
  const MarkdownLiteBlock();
}

class MarkdownLiteHeading extends MarkdownLiteBlock {
  const MarkdownLiteHeading(this.text);
  final String text;

  @override
  bool operator ==(Object other) =>
      other is MarkdownLiteHeading && other.text == text;
  @override
  int get hashCode => text.hashCode;
}

class MarkdownLiteParagraph extends MarkdownLiteBlock {
  const MarkdownLiteParagraph(this.text);
  final String text;

  @override
  bool operator ==(Object other) =>
      other is MarkdownLiteParagraph && other.text == text;
  @override
  int get hashCode => text.hashCode;
}

class MarkdownLiteBulletList extends MarkdownLiteBlock {
  const MarkdownLiteBulletList(this.items);
  final List<String> items;

  @override
  bool operator ==(Object other) {
    if (other is! MarkdownLiteBulletList ||
        other.items.length != items.length) {
      return false;
    }
    for (var i = 0; i < items.length; i++) {
      if (other.items[i] != items[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(items);
}

/// Splits [source] into blocks, line by line.
List<MarkdownLiteBlock> parseMarkdownLiteBlocks(String source) {
  final lines = source.split('\n');
  final blocks = <MarkdownLiteBlock>[];
  final paragraphBuffer = <String>[];
  final bulletBuffer = <String>[];

  void flushParagraph() {
    if (paragraphBuffer.isEmpty) return;
    blocks.add(MarkdownLiteParagraph(paragraphBuffer.join(' ')));
    paragraphBuffer.clear();
  }

  void flushBullets() {
    if (bulletBuffer.isEmpty) return;
    blocks.add(MarkdownLiteBulletList(List.of(bulletBuffer)));
    bulletBuffer.clear();
  }

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      flushParagraph();
      flushBullets();
    } else if (line.startsWith('## ')) {
      flushParagraph();
      flushBullets();
      blocks.add(MarkdownLiteHeading(line.substring(3).trim()));
    } else if (line.startsWith('- ')) {
      flushParagraph();
      bulletBuffer.add(line.substring(2).trim());
    } else {
      flushBullets();
      paragraphBuffer.add(line);
    }
  }
  flushParagraph();
  flushBullets();

  return blocks;
}

/// A `**bold**` span, or plain text -- [isBold] distinguishes them.
class MarkdownLiteSpan {
  const MarkdownLiteSpan(this.text, {required this.isBold});
  final String text;
  final bool isBold;

  @override
  bool operator ==(Object other) =>
      other is MarkdownLiteSpan && other.text == text && other.isBold == isBold;
  @override
  int get hashCode => Object.hash(text, isBold);
}

final _boldPattern = RegExp(r'\*\*(.+?)\*\*');

/// Splits inline `**bold**` spans out of [text], preserving the plain
/// text around them in order.
List<MarkdownLiteSpan> parseMarkdownLiteInline(String text) {
  final spans = <MarkdownLiteSpan>[];
  var cursor = 0;
  for (final match in _boldPattern.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
          MarkdownLiteSpan(text.substring(cursor, match.start), isBold: false));
    }
    spans.add(MarkdownLiteSpan(match.group(1)!, isBold: true));
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(MarkdownLiteSpan(text.substring(cursor), isBold: false));
  }
  return spans;
}
