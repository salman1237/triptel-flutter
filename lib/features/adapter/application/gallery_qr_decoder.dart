import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// FR-L902: picks an image from the gallery and decodes any QR code in
/// it -- a seam so widget tests don't need the real camera/gallery
/// plugins. `null` means the user cancelled the picker or no QR code
/// was found in the picked image -- both normal, non-error states (the
/// other three input sources stay available either way).
typedef GalleryQrDecoder = Future<String?> Function();

final galleryQrDecoderProvider = Provider<GalleryQrDecoder>((ref) => () async {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return null;
      final capture = await MobileScannerController().analyzeImage(file.path);
      if (capture == null || capture.barcodes.isEmpty) return null;
      return capture.barcodes.first.rawValue;
    });
