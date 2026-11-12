import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// `flutter_secure_storage` has no official test API (unlike
/// `shared_preferences`'s `setMockInitialValues`), so this fakes its method
/// channel with an in-memory map — enough to exercise `SecureStore` and
/// `AuthNotifier` in tests without touching a real keychain/keystore.
void installFakeSecureStorage() {
  final values = <String, String>{};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    channel,
    (call) async {
      switch (call.method) {
        case 'write':
          values[call.arguments['key'] as String] =
              call.arguments['value'] as String;
          return null;
        case 'read':
          return values[call.arguments['key'] as String];
        case 'delete':
          values.remove(call.arguments['key'] as String);
          return null;
        case 'deleteAll':
          values.clear();
          return null;
        case 'containsKey':
          return values.containsKey(call.arguments['key'] as String);
        case 'readAll':
          return values;
        default:
          return null;
      }
    },
  );
}
