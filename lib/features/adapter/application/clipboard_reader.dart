import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-L902: reads the system clipboard's plain text, if any -- a seam so
/// widget tests don't need the real `Clipboard` platform channel.
typedef ClipboardReader = Future<String?> Function();

final clipboardReaderProvider = Provider<ClipboardReader>((ref) => () async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    });
