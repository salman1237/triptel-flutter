import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/checkout/application/provisioning_steps.dart';

void main() {
  group('provisioningStepForElapsed (FR-308)', () {
    test('starts at paymentConfirmed', () {
      expect(provisioningStepForElapsed(Duration.zero),
          ProvisioningStep.paymentConfirmed);
      expect(provisioningStepForElapsed(const Duration(seconds: 2)),
          ProvisioningStep.paymentConfirmed);
    });

    test('advances to reservingEsim at 3s', () {
      expect(provisioningStepForElapsed(const Duration(seconds: 3)),
          ProvisioningStep.reservingEsim);
      expect(provisioningStepForElapsed(const Duration(seconds: 9)),
          ProvisioningStep.reservingEsim);
    });

    test('advances to preparingQr at 10s and stays there', () {
      expect(provisioningStepForElapsed(const Duration(seconds: 10)),
          ProvisioningStep.preparingQr);
      expect(provisioningStepForElapsed(const Duration(minutes: 5)),
          ProvisioningStep.preparingQr);
    });
  });
}
