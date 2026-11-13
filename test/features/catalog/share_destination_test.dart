import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/catalog/application/share_destination.dart';

void main() {
  test('builds the public explore URL for a slug', () {
    expect(destinationShareUrl('japan'), 'https://triptel.co/explore/japan');
  });

  test('does not percent-encode a plain slug', () {
    expect(destinationShareUrl('south-korea'),
        'https://triptel.co/explore/south-korea');
  });
}
