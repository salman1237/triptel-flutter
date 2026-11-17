import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';

void main() {
  test(
      'parses the real beta payment_methods/bangla_qr_image '
      '(API.md section 1)', () {
    final json = jsonDecode(
            File('test/fixtures/settings_public.json').readAsStringSync())
        as Map<String, dynamic>;

    final settings = PublicSettings.fromJson(json);

    expect(settings.paymentMethods, hasLength(1));
    final method = settings.paymentMethods.first;
    expect(method.id, 'bkash-account');
    expect(method.name, 'bKash Account');
    expect(method.kind, 'mobile');
    expect(method.accountNumber, '01750726094');
    expect(method.branch, isNull);
    expect(method.instructions, isNull);
    expect(method.isActive, isTrue);
    expect(settings.banglaQrImage,
        '/api/v1/uploads/branding/bangla_qr_image-69b07a9b5dee4ffba4221b0c182e4932.png');
  });

  test('no payment methods configured parses to an empty list, not null', () {
    final settings = PublicSettings.fromJson(const {
      'platform_name': 'Triptel',
      'maintenance_mode': false,
      'default_currency': 'EUR',
    });

    expect(settings.paymentMethods, isEmpty);
    expect(settings.banglaQrImage, isNull);
  });

  test('round-trips through toJson/fromJson (bootstrap cache, FR-002)', () {
    final json = jsonDecode(
            File('test/fixtures/settings_public.json').readAsStringSync())
        as Map<String, dynamic>;
    final original = PublicSettings.fromJson(json);

    final roundTripped = PublicSettings.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);

    expect(roundTripped.paymentMethods.first.name, 'bKash Account');
    expect(roundTripped.banglaQrImage, original.banglaQrImage);
  });
}
