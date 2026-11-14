import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/checkout/application/provisioning_steps.dart';
import 'package:triptel/features/checkout/presentation/provisioning_progress_view.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows all three step labels', (tester) async {
    await tester.pumpWidget(_wrap(const ProvisioningProgressView(
        currentStep: ProvisioningStep.paymentConfirmed)));

    expect(find.text('Payment confirmed'), findsOneWidget);
    expect(find.text('Reserving your eSIM'), findsOneWidget);
    expect(find.text('Preparing QR'), findsOneWidget);
  });

  testWidgets('the current step shows a spinner, not a checkmark',
      (tester) async {
    await tester.pumpWidget(_wrap(const ProvisioningProgressView(
        currentStep: ProvisioningStep.reservingEsim)));

    // One completed step (paymentConfirmed) -> one check icon.
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    // One active step (reservingEsim) -> one spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // One pending step (preparingQr) -> one outlined circle.
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
  });

  testWidgets('the final step shows two checkmarks and one spinner',
      (tester) async {
    await tester.pumpWidget(_wrap(const ProvisioningProgressView(
        currentStep: ProvisioningStep.preparingQr)));

    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNothing);
  });
}
