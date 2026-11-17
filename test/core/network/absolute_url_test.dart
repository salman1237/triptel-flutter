import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/absolute_url.dart';

void main() {
  test(
      'resolves a server-relative upload path to the real beta host '
      '(confirmed live: curl -o /dev/null -w "%{http_code}" on the '
      'resolved URL returned 200 image/png)', () {
    final url = resolveApiUrl(
        '/api/v1/uploads/branding/bangla_qr_image-69b07a9b5dee4ffba4221b0c182e4932.png');

    expect(
        url,
        'https://beta.triptel.co/api/v1/uploads/branding/'
        'bangla_qr_image-69b07a9b5dee4ffba4221b0c182e4932.png');
  });
}
