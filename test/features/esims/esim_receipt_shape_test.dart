import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/esims/application/esim_receipt_shape.dart';
import 'package:triptel/features/esims/data/models/esim_status.dart';

EsimStatusProduct _product({
  bool isUnlimited = false,
  double dataAmountGb = 1.0,
}) =>
    EsimStatusProduct(
      title: 'Test plan',
      validityDays: 7,
      isUnlimited: isUnlimited,
      dataAmountGb: dataAmountGb,
    );

void main() {
  test('unlimited shows "Unlimited" regardless of dataAmountGb', () {
    expect(receiptDataLabel(_product(isUnlimited: true, dataAmountGb: 0)),
        'Unlimited');
  });

  test('below 1 GB shows rounded MB', () {
    expect(receiptDataLabel(_product(dataAmountGb: 0.1)), '100 MB');
  });

  test('a whole GB shows no trailing decimal', () {
    expect(receiptDataLabel(_product(dataAmountGb: 3.0)), '3 GB');
  });

  test('a fractional GB trims trailing zeros but keeps real precision', () {
    expect(receiptDataLabel(_product(dataAmountGb: 1.5)), '1.5 GB');
  });
}
