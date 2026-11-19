import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/clipboard_reader.dart';
import 'package:triptel/features/adapter/application/gallery_qr_decoder.dart';
import 'package:triptel/features/adapter/application/scanner_builder.dart';
import 'package:triptel/features/adapter/presentation/activation_input_screen.dart';

const _lpa = r'LPA:1$smdp.example.invalid$ACTIVATION-CODE';

Widget _app({
  ClipboardReader? clipboardReader,
  GalleryQrDecoder? galleryQrDecoder,
  ScannerBuilder? scannerBuilder,
}) =>
    ProviderScope(
      overrides: [
        if (clipboardReader != null)
          clipboardReaderProvider.overrideWithValue(clipboardReader),
        if (galleryQrDecoder != null)
          galleryQrDecoderProvider.overrideWithValue(galleryQrDecoder),
        scannerBuilderProvider.overrideWithValue(
          scannerBuilder ??
              (onCode, onError) =>
                  const SizedBox.shrink(key: ValueKey('stub-scanner')),
        ),
      ],
      child: const MaterialApp(home: ActivationInputScreen()),
    );

void main() {
  group('FR-L902: activation code input', () {
    testWidgets('manual form: empty SM-DP+ address shows a clear error',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final submit =
          find.byKey(const ValueKey('activation-input-manual-submit-button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('activation-input-error')), findsOneWidget);
      expect(find.text('Enter the SM-DP+ address.'), findsOneWidget);
    });

    testWidgets(
        'manual form: a valid SM-DP+ address and matching id shows the '
        'masked preview', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('activation-input-smdp-field')),
          'smdp.example.invalid');
      await tester.enterText(
          find.byKey(const ValueKey('activation-input-matching-id-field')),
          'ABCDEFGH');
      final submit =
          find.byKey(const ValueKey('activation-input-manual-submit-button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('activation-input-preview')),
          findsOneWidget);
      expect(find.text('smdp.example.invalid · ABCD…'), findsOneWidget);
    });

    testWidgets(
        'manual form: checking "confirmation code required" shows the hint '
        'in the preview', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('activation-input-smdp-field')),
          'smdp.example.invalid');
      final checkbox = find.byKey(
          const ValueKey('activation-input-confirmation-required-checkbox'));
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      final submit =
          find.byKey(const ValueKey('activation-input-manual-submit-button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(
          find.text('A confirmation code will be required.'), findsOneWidget);
    });

    testWidgets('pasting a valid code from the clipboard shows the preview',
        (tester) async {
      await tester.pumpWidget(_app(clipboardReader: () async => _lpa));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('activation-input-paste-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('activation-input-preview')),
          findsOneWidget);
    });

    testWidgets('an empty clipboard shows a clear message, never crashes',
        (tester) async {
      await tester.pumpWidget(_app(clipboardReader: () async => null));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('activation-input-paste-button')));
      await tester.pumpAndSettle();

      expect(find.text('Clipboard is empty.'), findsOneWidget);
    });

    testWidgets('scanning a QR from a gallery photo shows the preview',
        (tester) async {
      await tester.pumpWidget(_app(galleryQrDecoder: () async => _lpa));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('activation-input-gallery-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('activation-input-preview')),
          findsOneWidget);
    });

    testWidgets(
        'cancelling the gallery picker (null result) changes nothing, '
        'never crashes', (tester) async {
      await tester.pumpWidget(_app(galleryQrDecoder: () async => null));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('activation-input-gallery-button')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('activation-input-preview')), findsNothing);
      expect(
          find.byKey(const ValueKey('activation-input-error')), findsNothing);
    });

    testWidgets(
        'a live camera detection shows the preview via the faked scanner '
        'seam', (tester) async {
      await tester.pumpWidget(_app(
        scannerBuilder: (onCode, onError) => ElevatedButton(
          key: const ValueKey('fake-scan-trigger'),
          onPressed: () => onCode(_lpa),
          child: const Text('fake scan'),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('fake-scan-trigger')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('activation-input-preview')),
          findsOneWidget);
    });

    testWidgets(
        'a live camera detection fills the manual form fields too, so a '
        'later tap on "Use this code" re-submits the same data instead of '
        "clobbering the scan's preview with an empty-form error",
        (tester) async {
      await tester.pumpWidget(_app(
        scannerBuilder: (onCode, onError) => ElevatedButton(
          key: const ValueKey('fake-scan-trigger'),
          onPressed: () => onCode(_lpa),
          child: const Text('fake scan'),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('fake-scan-trigger')));
      await tester.pumpAndSettle();

      expect(
          find.widgetWithText(TextField, 'smdp.example.invalid',
              skipOffstage: false),
          findsOneWidget);
      expect(
          find.widgetWithText(TextField, 'ACTIVATION-CODE',
              skipOffstage: false),
          findsOneWidget);

      final submit =
          find.byKey(const ValueKey('activation-input-manual-submit-button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('activation-input-preview')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('activation-input-error')), findsNothing);
    });

    testWidgets(
        'a camera error shows an inline message, not a blocking dialog -- '
        'the other input sources stay available', (tester) async {
      await tester.pumpWidget(_app(
        scannerBuilder: (onCode, onError) => ElevatedButton(
          key: const ValueKey('fake-scan-error-trigger'),
          onPressed: onError,
          child: const Text('fake error'),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('fake-scan-error-trigger')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('activation-input-camera-error')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('activation-input-gallery-button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('activation-input-paste-button')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('activation-input-manual-submit-button')),
          findsOneWidget);
    });

    testWidgets('an unparseable pasted string shows the typed error message',
        (tester) async {
      await tester.pumpWidget(
          _app(clipboardReader: () async => 'not an activation code'));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('activation-input-paste-button')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('activation-input-error')), findsOneWidget);
      expect(
          find.text("That doesn't look like an eSIM activation code (should "
              'start with LPA:).'),
          findsOneWidget);
    });
  });
}
