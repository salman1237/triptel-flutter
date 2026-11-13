import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/compatibility/data/models/esim_raw_signals.dart';

void main() {
  test('fromMap parses the Android channel payload shape', () {
    final signals = EsimRawSignals.fromMap(const {
      'platform': 'android',
      'osVersion': '14',
      'sdkInt': 34,
      'hasEuiccFeature': true,
      'euiccEnabled': true,
      'manufacturer': 'vivo',
      'brand': 'vivo',
      'model': 'V2344',
      'device': 'V2344',
    });

    expect(signals.platform, 'android');
    expect(signals.sdkInt, 34);
    expect(signals.hasEuiccFeature, true);
    expect(signals.euiccEnabled, true);
    expect(signals.brand, 'vivo');
    expect(signals.model, 'V2344');
  });

  test('fromMap parses the iOS channel payload shape', () {
    final signals = EsimRawSignals.fromMap(const {
      'platform': 'ios',
      'osVersion': '17.4',
      'supportsCellularPlan': true,
      'supportsEmbeddedSIM': true,
      'manufacturer': 'Apple',
      'brand': 'Apple',
      'model': 'iPhone14,5',
      'device': 'iPhone',
    });

    expect(signals.platform, 'ios');
    expect(signals.supportsEmbeddedSIM, true);
    expect(signals.supportsCellularPlan, true);
    expect(signals.model, 'iPhone14,5');
  });

  test('missing/unexpected keys fall back to null/unknown safely', () {
    final signals = EsimRawSignals.fromMap(const {});
    expect(signals.platform, 'unknown');
    expect(signals.sdkInt, isNull);
    expect(signals.hasEuiccFeature, isNull);
  });
}
