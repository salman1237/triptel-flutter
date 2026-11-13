import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/checkout/application/compatibility_gate.dart';
import 'package:triptel/features/compatibility/application/esim_verdict.dart';

void main() {
  test('supported proceeds straight through', () {
    expect(decideGateAction(EsimVerdictKind.supported), GateAction.proceed);
  });

  test('not supported shows the Buy Now, Use Later dialog', () {
    expect(decideGateAction(EsimVerdictKind.notSupported),
        GateAction.showNotSupportedDialog);
  });

  test('unknown shows the softer note', () {
    expect(
        decideGateAction(EsimVerdictKind.unknown), GateAction.showUnknownNote);
  });
}
