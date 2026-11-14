import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/checkout/application/install_link.dart';

void main() {
  group('buildInstallUrl (FR-310/404, API.md "Install links")', () {
    const lpa = r'LPA:1$smdp.example.invalid$ACTIVATION-CODE';

    test('builds the Apple universal link on iOS', () {
      final url = buildInstallUrl(lpa, isIOS: true);
      expect(url,
          'https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=${Uri.encodeComponent(lpa)}');
    });

    test('builds the Android universal link on Android', () {
      final url = buildInstallUrl(lpa, isIOS: false);
      expect(url,
          'https://esimsetup.android.com/esim_qrcode_provisioning?carddata=${Uri.encodeComponent(lpa)}');
    });

    test('returns null when the string does not start with LPA:', () {
      expect(buildInstallUrl('not-an-lpa-string', isIOS: true), isNull);
      expect(buildInstallUrl('', isIOS: false), isNull);
    });
  });
}
