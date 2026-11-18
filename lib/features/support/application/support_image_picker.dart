import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// FR-1102's attachment picker -- same provider-seam pattern as FR-1003's
/// `kycImagePickerProvider`, so widget tests override this instead of
/// driving the real platform channel. Images only (png/jpeg/webp/heic);
/// the API also accepts pdf/txt (API.md section 12), but this app has no
/// general file-picker dependency and a second one (on top of
/// `image_picker`) wasn't justified for two rarely-used attachment types
/// -- a disclosed limitation, see DECISIONS.md.
typedef SupportImagePicker = Future<String?> Function();

final supportImagePickerProvider =
    Provider<SupportImagePicker>((ref) => () async {
          final file = await ImagePicker()
              .pickImage(source: ImageSource.gallery, imageQuality: 85);
          return file?.path;
        });
