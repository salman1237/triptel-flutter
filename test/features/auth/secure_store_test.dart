import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/storage/secure_store.dart';
import 'secure_storage_test_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('readToken is null before anything is saved', () async {
    installFakeSecureStorage();
    final store = SecureStore();
    expect(await store.readToken(), isNull);
  });

  test('saveToken persists the token and the must_change_password flag',
      () async {
    installFakeSecureStorage();
    final store = SecureStore();

    await store.saveToken('jwt-123', mustChangePassword: true);

    expect(await store.readToken(), 'jwt-123');
    expect(await store.readMustChangePassword(), isTrue);
  });

  test('clear removes both the token and the flag', () async {
    installFakeSecureStorage();
    final store = SecureStore();
    await store.saveToken('jwt-123', mustChangePassword: true);

    await store.clear();

    expect(await store.readToken(), isNull);
    expect(await store.readMustChangePassword(), isFalse);
  });
}
