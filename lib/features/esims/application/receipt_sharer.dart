import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// FR-409: the real receipt's PNG share payload -- a plain function so it's
/// testable without a widget tree (Architecture.md).
ShareParams receiptShareParams(Uint8List pngBytes) => ShareParams(
      files: [
        XFile.fromData(pngBytes, mimeType: 'image/png', name: 'receipt.png'),
      ],
    );

/// Captures the widget under [boundaryKey] as a PNG and shares it. A
/// provider seam -- widget tests override this instead of driving a real
/// platform [RenderRepaintBoundary.toImage] capture, same reasoning as
/// `shurjoPayLauncherProvider`'s own doc comment (can't reliably drive
/// real engine image capture inside the fake-async widget test clock).
typedef ReceiptSharer = Future<void> Function(GlobalKey boundaryKey);

final receiptSharerProvider =
    Provider<ReceiptSharer>((ref) => (boundaryKey) async {
          final boundary = boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary == null) return;
          final image = await boundary.toImage(pixelRatio: 2.0);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          if (bytes == null) return;
          await SharePlus.instance
              .share(receiptShareParams(bytes.buffer.asUint8List()));
        });
