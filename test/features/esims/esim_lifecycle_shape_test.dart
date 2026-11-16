import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/application/esim_lifecycle_shape.dart';

void main() {
  group('lifecycleBannerMessage', () {
    test('normal statuses have no banner', () {
      for (final status in ['ALLOCATED', 'RELEASED', 'INSTALLED', 'ACTIVE']) {
        expect(lifecycleBannerMessage(status), isNull, reason: status);
      }
    });

    test('each terminal status has its own distinct message', () {
      final suspended = lifecycleBannerMessage('SUSPENDED');
      final revoked = lifecycleBannerMessage('REVOKED');
      final cancelled = lifecycleBannerMessage('CANCELLED');
      final expired = lifecycleBannerMessage('EXPIRED');

      expect(suspended, isNotNull);
      expect(revoked, isNotNull);
      expect(cancelled, isNotNull);
      expect(expired, isNotNull);

      final messages = {suspended, revoked, cancelled, expired};
      expect(messages, hasLength(4), reason: 'messages must be distinct');

      for (final message in messages) {
        expect(message, contains('install and top-up are unavailable'));
      }
    });

    test('unknown status has no banner (never crashes)', () {
      expect(lifecycleBannerMessage('SOMETHING_NEW'), isNull);
    });
  });

  group('installAndTopupDisabled', () {
    test('true for every terminal status', () {
      for (final status in ['SUSPENDED', 'REVOKED', 'CANCELLED', 'EXPIRED']) {
        expect(installAndTopupDisabled(status), isTrue, reason: status);
      }
    });

    test('false for every normal status', () {
      for (final status in ['ALLOCATED', 'RELEASED', 'INSTALLED', 'ACTIVE']) {
        expect(installAndTopupDisabled(status), isFalse, reason: status);
      }
    });
  });
}
