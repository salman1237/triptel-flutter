import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/support/data/models/support_category.dart';

void main() {
  test(
      'SupportCategory.fromJson parses the documented GET /support/'
      'categories response (API.md section 12)', () {
    final category = SupportCategory.fromJson(
        const {'value': 'ESIM', 'label': 'eSIM not working'});

    expect(category.value, 'ESIM');
    expect(category.label, 'eSIM not working');
  });
}
