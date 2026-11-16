import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/application/receipt_sharer.dart';

void main() {
  test(
      'receiptShareParams shares exactly one image/png file with the '
      'given bytes', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);

    final params = receiptShareParams(bytes);

    expect(params.files, hasLength(1));
    expect(params.files!.single.mimeType, 'image/png');
    expect(await params.files!.single.readAsBytes(), bytes);
  });
}
