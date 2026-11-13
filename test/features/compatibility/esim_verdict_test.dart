import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/compatibility/application/esim_verdict.dart';
import 'package:triptel/features/compatibility/data/models/esim_raw_signals.dart';

EsimRawSignals _android({
  int? sdkInt,
  bool? hasEuiccFeature,
  bool? euiccEnabled,
  String brand = 'vivo',
  String model = 'V2344',
}) =>
    EsimRawSignals(
      platform: 'android',
      osVersion: '14',
      manufacturer: brand,
      brand: brand,
      model: model,
      device: model,
      sdkInt: sdkInt,
      hasEuiccFeature: hasEuiccFeature,
      euiccEnabled: euiccEnabled,
    );

EsimRawSignals _ios({
  bool? supportsEmbeddedSIM,
  bool? supportsCellularPlan,
  String model = 'iPhone14,5',
}) =>
    EsimRawSignals(
      platform: 'ios',
      osVersion: '17.4',
      manufacturer: 'Apple',
      brand: 'Apple',
      model: model,
      device: 'iPhone',
      supportsEmbeddedSIM: supportsEmbeddedSIM,
      supportsCellularPlan: supportsCellularPlan,
    );

void main() {
  group('Android', () {
    test('API < 28 is unknown (too old to check)', () {
      final verdict = evaluateEsimSupport(_android(sdkInt: 26));
      expect(verdict.kind, EsimVerdictKind.unknown);
    });

    test('no EUICC feature is not supported', () {
      final verdict =
          evaluateEsimSupport(_android(sdkInt: 33, hasEuiccFeature: false));
      expect(verdict.kind, EsimVerdictKind.notSupported);
    });

    test('EUICC feature + enabled is supported', () {
      final verdict = evaluateEsimSupport(
          _android(sdkInt: 33, hasEuiccFeature: true, euiccEnabled: true));
      expect(verdict.kind, EsimVerdictKind.supported);
    });

    test('EUICC feature present but disabled is unknown, not "not supported"',
        () {
      final verdict = evaluateEsimSupport(
          _android(sdkInt: 33, hasEuiccFeature: true, euiccEnabled: false));
      expect(verdict.kind, EsimVerdictKind.unknown);
    });

    test('EUICC feature present but enabled-check errored is unknown', () {
      final verdict = evaluateEsimSupport(
          _android(sdkInt: 33, hasEuiccFeature: true, euiccEnabled: null));
      expect(verdict.kind, EsimVerdictKind.unknown);
    });

    test('device label joins brand and model', () {
      final verdict = evaluateEsimSupport(
          _android(sdkInt: 33, hasEuiccFeature: true, euiccEnabled: true));
      expect(verdict.deviceLabel, 'vivo V2344');
    });
  });

  group('iOS', () {
    test('supportsEmbeddedSIM true is supported', () {
      final verdict = evaluateEsimSupport(_ios(supportsEmbeddedSIM: true));
      expect(verdict.kind, EsimVerdictKind.supported);
    });

    test('supportsEmbeddedSIM false is not supported', () {
      final verdict = evaluateEsimSupport(_ios(supportsEmbeddedSIM: false));
      expect(verdict.kind, EsimVerdictKind.notSupported);
    });

    test('pre-iOS16 falls back to supportsCellularPlan', () {
      final verdict = evaluateEsimSupport(_ios(
        supportsEmbeddedSIM: null,
        supportsCellularPlan: true,
      ));
      expect(verdict.kind, EsimVerdictKind.supported);
    });

    test('no usable signal at all is unknown', () {
      final verdict = evaluateEsimSupport(_ios(
        supportsEmbeddedSIM: null,
        supportsCellularPlan: null,
      ));
      expect(verdict.kind, EsimVerdictKind.unknown);
    });

    test('device label maps a known machine identifier to a marketing name',
        () {
      final verdict = evaluateEsimSupport(
          _ios(supportsEmbeddedSIM: true, model: 'iPhone14,5'));
      expect(verdict.deviceLabel, 'iPhone 13');
    });

    test('device label falls back to the raw identifier when unmapped', () {
      final verdict = evaluateEsimSupport(
          _ios(supportsEmbeddedSIM: true, model: 'iPhone99,9'));
      expect(verdict.deviceLabel, 'iPhone99,9');
    });
  });

  test('an unrecognized platform is unknown', () {
    final verdict = evaluateEsimSupport(const EsimRawSignals(
      platform: 'unknown',
      osVersion: '',
      manufacturer: '',
      brand: '',
      model: '',
      device: '',
    ));
    expect(verdict.kind, EsimVerdictKind.unknown);
  });
}
