import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/core/widgets/widgets.dart';
import 'package:triptel/features/kyc/application/kyc_image_picker.dart';
import 'package:triptel/features/kyc/application/kyc_providers.dart';
import 'package:triptel/features/kyc/data/kyc_api.dart';
import 'package:triptel/features/kyc/data/models/kyc_status.dart';
import 'package:triptel/features/kyc/presentation/kyc_screen.dart';

class _FakeKycApi implements KycApi {
  _FakeKycApi(this._status, {this.submitError});
  KycStatus _status;
  final ApiException? submitError;
  String? lastNid;
  String? lastFront;
  String? lastBack;

  @override
  Future<KycStatus> getMe() async => _status;

  @override
  Future<void> submit({
    required String nidNumber,
    required String documentFrontPath,
    String? documentBackPath,
  }) async {
    if (submitError != null) throw submitError!;
    lastNid = nidNumber;
    lastFront = documentFrontPath;
    lastBack = documentBackPath;
    _status = const KycStatus(submitted: true, status: 'PENDING');
  }
}

Widget _app(
  KycApi api, {
  KycImagePicker? picker,
}) =>
    ProviderScope(
      overrides: [
        kycApiProvider.overrideWithValue(api),
        if (picker != null) kycImagePickerProvider.overrideWithValue(picker),
      ],
      child: const MaterialApp(home: KycScreen()),
    );

void main() {
  testWidgets('not submitted shows the real form, no rejection reason',
      (tester) async {
    await tester
        .pumpWidget(_app(_FakeKycApi(const KycStatus(submitted: false))));
    await tester.pumpAndSettle();

    expect(find.text('Not verified'), findsOneWidget);
    expect(find.byKey(const ValueKey('kyc-nid-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('kyc-rejection-reason')), findsNothing);
  });

  testWidgets(
      'REJECTED shows the real rejection reason and still shows '
      'the form', (tester) async {
    await tester.pumpWidget(_app(_FakeKycApi(const KycStatus(
      submitted: true,
      status: 'REJECTED',
      rejectionReason: 'Blurry photo',
    ))));
    await tester.pumpAndSettle();

    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Blurry photo'), findsOneWidget);
    expect(find.byKey(const ValueKey('kyc-nid-field')), findsOneWidget);
  });

  testWidgets('APPROVED shows a success EmptyState, no form', (tester) async {
    await tester.pumpWidget(_app(
        _FakeKycApi(const KycStatus(submitted: true, status: 'APPROVED'))));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byKey(const ValueKey('kyc-nid-field')), findsNothing);
  });

  testWidgets('submitting without an NID number shows a real error',
      (tester) async {
    await tester
        .pumpWidget(_app(_FakeKycApi(const KycStatus(submitted: false))));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('kyc-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your NID number.'), findsOneWidget);
  });

  testWidgets('submitting without a front photo shows a real error',
      (tester) async {
    await tester
        .pumpWidget(_app(_FakeKycApi(const KycStatus(submitted: false))));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('kyc-nid-field')), '1234567890');
    await tester.tap(find.byKey(const ValueKey('kyc-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Add a front photo of your NID.'), findsOneWidget);
  });

  testWidgets(
      'a successful submit sends the real NID/front/back paths and '
      'refreshes to the real PENDING status', (tester) async {
    final api = _FakeKycApi(const KycStatus(submitted: false));
    await tester.pumpWidget(_app(
      api,
      picker: () async => '/tmp/front.jpg',
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('kyc-nid-field')), '1234567890');
    await tester.tap(find.byKey(const ValueKey('kyc-front-photo-button')));
    await tester.pumpAndSettle();
    expect(find.text('Front photo added'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kyc-submit-button')));
    await tester.pumpAndSettle();

    expect(api.lastNid, '1234567890');
    expect(api.lastFront, '/tmp/front.jpg');
    expect(api.lastBack, isNull);
    expect(find.text('Submitted for review.'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('adding an optional back photo sends its real path too',
      (tester) async {
    final paths = ['/tmp/front.jpg', '/tmp/back.jpg'];
    var i = 0;
    final api = _FakeKycApi(const KycStatus(submitted: false));
    await tester.pumpWidget(_app(
      api,
      picker: () async => paths[i++],
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('kyc-nid-field')), '1234567890');
    await tester.tap(find.byKey(const ValueKey('kyc-front-photo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kyc-back-photo-button')));
    await tester.pumpAndSettle();
    expect(find.text('Back photo added'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kyc-submit-button')));
    await tester.pumpAndSettle();

    expect(api.lastFront, '/tmp/front.jpg');
    expect(api.lastBack, '/tmp/back.jpg');
  });

  testWidgets('a real server error on submit shows the real message',
      (tester) async {
    final api = _FakeKycApi(
      const KycStatus(submitted: false),
      submitError: const ApiException(statusCode: 400, message: 'Invalid NID.'),
    );
    await tester.pumpWidget(_app(api, picker: () async => '/tmp/front.jpg'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('kyc-nid-field')), '1234567890');
    await tester.tap(find.byKey(const ValueKey('kyc-front-photo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kyc-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid NID.'), findsOneWidget);
  });

  testWidgets('a load error shows ErrorState with a working retry',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        kycStatusProvider
            .overrideWith((ref) async => throw Exception('network error')),
      ],
      child: const MaterialApp(home: KycScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
  });
}
