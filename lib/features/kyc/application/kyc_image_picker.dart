import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// FR-1003's document photo picker -- a provider seam so widget tests
/// override this instead of driving the real platform image picker
/// (same reasoning as `urlLauncherProvider`/`topupLauncherProvider`).
/// Returns the picked file's path, or null if the user cancelled.
typedef KycImagePicker = Future<String?> Function();

final kycImagePickerProvider = Provider<KycImagePicker>((ref) => () async {
      final file = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85);
      return file?.path;
    });
