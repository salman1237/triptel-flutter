import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/auth/application/register_validation.dart';

void main() {
  group('validateRegisterPassword', () {
    test('rejects passwords under 8 characters', () {
      expect(validateRegisterPassword('short1'), isNotNull);
    });

    test('accepts passwords of 8 or more characters', () {
      expect(validateRegisterPassword('min8chars'), isNull);
    });
  });

  group('validateEmail', () {
    test('rejects empty email', () {
      expect(validateEmail(''), isNotNull);
    });

    test('rejects a string without @ or .', () {
      expect(validateEmail('notanemail'), isNotNull);
    });

    test('accepts a plausible email', () {
      expect(validateEmail('a@b.co'), isNull);
    });
  });

  group('validateUsername', () {
    test('rejects empty username', () {
      expect(validateUsername('   '), isNotNull);
    });

    test('accepts a non-empty username', () {
      expect(validateUsername('alice'), isNull);
    });
  });
}
