import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/application/esim_install_links.dart';

void main() {
  test('derives the web setup guide URL from the beta API base URL', () {
    expect(setupGuideUrl(), 'https://beta.triptel.co/guides/esim-setup-guide');
  });
}
