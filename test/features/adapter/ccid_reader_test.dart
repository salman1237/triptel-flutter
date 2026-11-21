import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/ccid_reader.dart';

void main() {
  group('CcidReader.fromRaw', () {
    test('parses the documented shape from UsbCcidReaders.kt', () {
      final reader = CcidReader.fromRaw({
        'id': 2,
        'name': 'EMV Smartcard Reader',
        'vendorId': 11491,
        'productId': 38243,
        'hasPermission': false,
      });

      expect(reader.id, 2);
      expect(reader.name, 'EMV Smartcard Reader');
      expect(reader.vendorId, 11491);
      expect(reader.productId, 38243);
      expect(reader.hasPermission, isFalse);
    });

    test('a granted reader carries hasPermission true', () {
      final reader = CcidReader.fromRaw({
        'id': 2,
        'name': 'EMV Smartcard Reader',
        'vendorId': 11491,
        'productId': 38243,
        'hasPermission': true,
      });

      expect(reader.hasPermission, isTrue);
    });

    test('a missing product name falls back to a plain label, never null', () {
      final reader = CcidReader.fromRaw({
        'id': 1,
        'vendorId': 0,
        'productId': 0,
        'hasPermission': false,
      });

      expect(reader.name, 'Unknown reader');
    });
  });

  group('CcidReader.fromRawList', () {
    test('parses an empty list (no reader attached)', () {
      expect(CcidReader.fromRawList(const []), isEmpty);
    });

    test('parses multiple readers', () {
      final readers = CcidReader.fromRawList([
        {
          'id': 1,
          'name': 'Reader A',
          'vendorId': 1,
          'productId': 1,
          'hasPermission': true,
        },
        {
          'id': 2,
          'name': 'Reader B',
          'vendorId': 2,
          'productId': 2,
          'hasPermission': false,
        },
      ]);

      expect(readers, hasLength(2));
      expect(readers[0].name, 'Reader A');
      expect(readers[1].name, 'Reader B');
    });
  });
}
