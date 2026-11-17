import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/account/application/track_input.dart';

void main() {
  test('extracts the token from a real full tracking link', () {
    expect(resolveTrackingToken('https://triptel.co/track/ABC123'), 'ABC123');
  });

  test('extracts the token from a beta tracking link', () {
    expect(
        resolveTrackingToken('https://beta.triptel.co/track/XYZ789'), 'XYZ789');
  });

  test('a bare token is used as-is', () {
    expect(resolveTrackingToken('BARE123'), 'BARE123');
  });

  test('trims surrounding whitespace', () {
    expect(resolveTrackingToken('  BARE123  '), 'BARE123');
  });

  test('empty input returns null', () {
    expect(resolveTrackingToken(''), isNull);
    expect(resolveTrackingToken('   '), isNull);
  });

  test('an unrelated URL falls back to the raw input', () {
    expect(resolveTrackingToken('https://example.com/foo'),
        'https://example.com/foo');
  });
}
