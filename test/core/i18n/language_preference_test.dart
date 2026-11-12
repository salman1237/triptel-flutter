import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/i18n/language_preference.dart';
import 'package:triptel/features/bootstrap/data/models/language.dart';

const _en = Language(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    isActive: true,
    isRtl: false);
const _ar = Language(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
    isActive: true,
    isRtl: true);
const _bn = Language(
    code: 'bn',
    name: 'Bengali',
    nativeName: 'বাংলা',
    isActive: false,
    isRtl: false);

void main() {
  group('resolveInitialLanguage', () {
    test('uses the stored code when it is still active', () {
      expect(
        resolveInitialLanguage(storedCode: 'ar', available: const [_en, _ar]),
        'ar',
      );
    });

    test('falls back to English when nothing was stored', () {
      expect(
        resolveInitialLanguage(storedCode: null, available: const [_en, _ar]),
        'en',
      );
    });

    test('falls back to English when the stored language is no longer active',
        () {
      expect(
        resolveInitialLanguage(
            storedCode: 'bn', available: const [_en, _ar, _bn]),
        'en',
      );
    });

    test('falls back to the first active language when English is unavailable',
        () {
      expect(
        resolveInitialLanguage(storedCode: null, available: const [_ar]),
        'ar',
      );
    });
  });

  group('isRtlLanguage', () {
    test('true for a language flagged is_rtl', () {
      expect(isRtlLanguage('ar', const [_en, _ar]), isTrue);
    });

    test('false for a language not flagged is_rtl', () {
      expect(isRtlLanguage('en', const [_en, _ar]), isFalse);
    });

    test('false for an unknown code rather than guessing', () {
      expect(isRtlLanguage('xx', const [_en, _ar]), isFalse);
    });
  });

  group('translate', () {
    test('returns the namespaced value when present', () {
      final namespaces = {
        'common': {'save': 'Save'},
      };
      expect(translate(namespaces, ns: 'common', key: 'save', fallback: 'Save'),
          'Save');
    });

    test('falls back when the namespace is missing', () {
      expect(translate(const {}, ns: 'common', key: 'save', fallback: 'Save'),
          'Save');
    });

    test('falls back when the key is missing from an existing namespace', () {
      final namespaces = {
        'common': {'cancel': 'Cancel'},
      };
      expect(translate(namespaces, ns: 'common', key: 'save', fallback: 'Save'),
          'Save');
    });
  });
}
