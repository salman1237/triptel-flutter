import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/support/application/contact_shortcuts.dart';

void main() {
  test('contactWhatsappUri strips formatting to wa.me/<digits>', () {
    expect(
      contactWhatsappUri('+880 1979-891996').toString(),
      'https://wa.me/8801979891996',
    );
  });

  test('contactWhatsappUri keeps a plain digit string as-is', () {
    expect(
      contactWhatsappUri('8801979891996').toString(),
      'https://wa.me/8801979891996',
    );
  });

  test('contactPhoneUri builds a real tel: link', () {
    expect(contactPhoneUri('+8801979891996').toString(), 'tel:+8801979891996');
  });

  test('contactEmailUri builds a real mailto: link', () {
    expect(contactEmailUri('support@triptel.co').toString(),
        'mailto:support@triptel.co');
  });
}
