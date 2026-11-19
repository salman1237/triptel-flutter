import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/activation_code.dart';

void main() {
  group('parseActivationCode', () {
    test(
        'parses the minimal documented shape (API.md: '
        'lpa_string example "LPA:1\$smdp.io\$ABC")', () {
      final result = parseActivationCode(r'LPA:1$smdp.io$ABC');

      expect(result, isA<ActivationCodeParsed>());
      final code = (result as ActivationCodeParsed).code;
      expect(code.smdpAddress, 'smdp.io');
      expect(code.matchingId, 'ABC');
      expect(code.smdpOid, isNull);
      expect(code.confirmationCodeRequired, isFalse);
    });

    test('accepts an empty matching id (SM-DS lookup case)', () {
      final result = parseActivationCode(r'LPA:1$smdp.io$');

      expect(result, isA<ActivationCodeParsed>());
      expect((result as ActivationCodeParsed).code.matchingId, '');
    });

    test(
        'parses the full 5-field form with an oid and the confirmation '
        'flag set', () {
      final result = parseActivationCode(r'LPA:1$smdp.io$ABC$1.2.3.4$1');

      final code = (result as ActivationCodeParsed).code;
      expect(code.smdpOid, '1.2.3.4');
      expect(code.confirmationCodeRequired, isTrue);
    });

    test('flag "0" means confirmation code is not required', () {
      final result = parseActivationCode(r'LPA:1$smdp.io$ABC$$0');

      final code = (result as ActivationCodeParsed).code;
      expect(code.confirmationCodeRequired, isFalse);
    });

    test(
        'accepts the lowercase lpa: deep-link scheme (OpenEUICC_Reference '
        'section 2.4)', () {
      final result = parseActivationCode(r'lpa:1$rsp.example.com$matching-id');

      expect(result, isA<ActivationCodeParsed>());
      final code = (result as ActivationCodeParsed).code;
      expect(code.smdpAddress, 'rsp.example.com');
      expect(code.matchingId, 'matching-id');
    });

    test(
        'unwraps the documented carddata install-link URL (API.md '
        '"Install links")', () {
      final url = 'https://esimsetup.android.com/esim_qrcode_provisioning'
          '?carddata=${Uri.encodeQueryComponent(r'LPA:1$smdp.io$ABC')}';

      final result = parseActivationCode(url);

      expect(result, isA<ActivationCodeParsed>());
      final code = (result as ActivationCodeParsed).code;
      expect(code.smdpAddress, 'smdp.io');
      expect(code.matchingId, 'ABC');
    });

    test('trims surrounding whitespace (e.g. from a clipboard paste)', () {
      final result = parseActivationCode('  LPA:1\$smdp.io\$ABC  \n');

      expect(result, isA<ActivationCodeParsed>());
    });

    test('rejects a string with the wrong prefix', () {
      final result = parseActivationCode('not-an-activation-code');

      expect(
          result, const ActivationCodeInvalid(ActivationCodeError.wrongPrefix));
    });

    test('rejects an unsupported version', () {
      final result = parseActivationCode(r'LPA:2$smdp.io$ABC');

      expect(result,
          const ActivationCodeInvalid(ActivationCodeError.unsupportedVersion));
    });

    test('rejects too few fields (missing matching-id slot entirely)', () {
      final result = parseActivationCode(r'LPA:1$smdp.io');

      expect(result,
          const ActivationCodeInvalid(ActivationCodeError.tooFewFields));
    });

    test('rejects an empty smdp-address', () {
      final result = parseActivationCode(r'LPA:1$$ABC');

      expect(result,
          const ActivationCodeInvalid(ActivationCodeError.missingSmdpAddress));
    });

    test('rejects too many fields', () {
      final result = parseActivationCode(r'LPA:1$smdp.io$ABC$oid$1$extra');

      expect(result,
          const ActivationCodeInvalid(ActivationCodeError.tooManyFields));
    });

    test('rejects a non-0/1 confirmation-code flag', () {
      final result = parseActivationCode(r'LPA:1$smdp.io$ABC$oid$yes');

      expect(
          result,
          const ActivationCodeInvalid(
              ActivationCodeError.invalidConfirmationCodeFlag));
    });

    test(
        'a URL without a carddata param is parsed as plain text (and '
        'correctly rejected -- not silently treated as a valid code)', () {
      final result = parseActivationCode('https://example.com/no-code-here');

      expect(result, isA<ActivationCodeInvalid>());
    });

    test(
        'an explicit-but-empty 4th field (trailing \$) parses as an empty '
        'oid, distinct from an absent one (null)', () {
      final result = parseActivationCode(r'LPA:1$smdp.io$ABC$');

      final code = (result as ActivationCodeParsed).code;
      expect(code.matchingId, 'ABC');
      expect(code.smdpOid, '');
    });
  });

  group('ActivationCode.toLpaString', () {
    test('round-trips the minimal 2-field form', () {
      const code = ActivationCode(smdpAddress: 'smdp.io', matchingId: 'ABC');

      final roundTripped = parseActivationCode(code.toLpaString());

      expect(roundTripped, isA<ActivationCodeParsed>());
      final parsed = (roundTripped as ActivationCodeParsed).code;
      expect(parsed.smdpAddress, 'smdp.io');
      expect(parsed.matchingId, 'ABC');
      expect(parsed.confirmationCodeRequired, isFalse);
    });

    test('round-trips with an oid and confirmation code required', () {
      const code = ActivationCode(
        smdpAddress: 'smdp.io',
        matchingId: 'ABC',
        smdpOid: '1.2.3.4',
        confirmationCodeRequired: true,
      );

      final roundTripped = parseActivationCode(code.toLpaString());

      final parsed = (roundTripped as ActivationCodeParsed).code;
      expect(parsed.smdpOid, '1.2.3.4');
      expect(parsed.confirmationCodeRequired, isTrue);
    });
  });

  group('ActivationCode.maskedLabel', () {
    test('truncates a long matching id', () {
      const code =
          ActivationCode(smdpAddress: 'smdp.io', matchingId: 'ABCDEFGH');

      expect(code.maskedLabel(), 'smdp.io · ABCD…');
    });

    test('shows a short matching id in full', () {
      const code = ActivationCode(smdpAddress: 'smdp.io', matchingId: 'AB');

      expect(code.maskedLabel(), 'smdp.io · AB');
    });

    test('labels an empty matching id explicitly', () {
      const code = ActivationCode(smdpAddress: 'smdp.io', matchingId: '');

      expect(code.maskedLabel(), 'smdp.io · (no matching id)');
    });
  });

  group('buildActivationCodeFromOrderData', () {
    test('prefers the full lpa_string when present (API.md section 7)', () {
      final result = buildActivationCodeFromOrderData(
        lpaString: r'LPA:1$smdp.io$ABC',
        smdpAddress: 'other.example',
        matchingId: 'WRONG',
      );

      final code = (result as ActivationCodeParsed).code;
      expect(code.smdpAddress, 'smdp.io');
      expect(code.matchingId, 'ABC');
    });

    test(
        'falls back to smdp_address + matching_id when lpa_string is '
        'absent', () {
      final result = buildActivationCodeFromOrderData(
        smdpAddress: 'smdp.io',
        matchingId: 'ABC',
      );

      final code = (result as ActivationCodeParsed).code;
      expect(code.smdpAddress, 'smdp.io');
      expect(code.matchingId, 'ABC');
    });

    test(
        'falls back to an empty matching id when only smdp_address is '
        'given', () {
      final result = buildActivationCodeFromOrderData(smdpAddress: 'smdp.io');

      final code = (result as ActivationCodeParsed).code;
      expect(code.matchingId, '');
    });

    test('returns a typed error when no usable data is present', () {
      final result = buildActivationCodeFromOrderData();

      expect(result,
          const ActivationCodeInvalid(ActivationCodeError.missingSmdpAddress));
    });
  });
}
