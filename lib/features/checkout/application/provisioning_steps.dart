/// FR-308: the three steps shown while an order is provisioning, per
/// Functional_Requirements.md: "Payment confirmed -> Reserving your eSIM ->
/// Preparing QR; then success."
enum ProvisioningStep { paymentConfirmed, reservingEsim, preparingQr }

const provisioningStepLabels = <ProvisioningStep, String>{
  ProvisioningStep.paymentConfirmed: 'Payment confirmed',
  ProvisioningStep.reservingEsim: 'Reserving your eSIM',
  ProvisioningStep.preparingQr: 'Preparing QR',
};

/// API.md section 6 only exposes `PENDING|PAID|PROCESSING|COMPLETED|FAILED`
/// for the order as a whole, not sub-progress while `PROCESSING` (10-30s,
/// "sometimes longer") -- so the step shown advances on elapsed wall-clock
/// time, as a progress indicator over the real poll running underneath it.
ProvisioningStep provisioningStepForElapsed(Duration elapsed) {
  if (elapsed < const Duration(seconds: 3)) {
    return ProvisioningStep.paymentConfirmed;
  }
  if (elapsed < const Duration(seconds: 10)) {
    return ProvisioningStep.reservingEsim;
  }
  return ProvisioningStep.preparingQr;
}
