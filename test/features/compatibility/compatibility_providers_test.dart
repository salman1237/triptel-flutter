import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/compatibility/application/compatibility_providers.dart';
import 'package:triptel/features/compatibility/application/esim_verdict.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('co.triptel.app/esim');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('esimVerdictProvider reads the native channel and decides a verdict',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getEsimSupport');
      return <String, dynamic>{
        'platform': 'android',
        'osVersion': '14',
        'sdkInt': 34,
        'hasEuiccFeature': true,
        'euiccEnabled': true,
        'manufacturer': 'vivo',
        'brand': 'vivo',
        'model': 'V2344',
        'device': 'V2344',
      };
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final verdict = await container.read(esimVerdictProvider.future);

    expect(verdict.kind, EsimVerdictKind.supported);
    expect(verdict.deviceLabel, 'vivo V2344');
  });

  test('esimVerdictProvider is cached for the session (channel called once)',
      () async {
    var callCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      callCount++;
      return <String, dynamic>{
        'platform': 'android',
        'sdkInt': 34,
        'hasEuiccFeature': true,
        'euiccEnabled': true,
        'manufacturer': 'vivo',
        'brand': 'vivo',
        'model': 'V2344',
        'device': 'V2344',
      };
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(esimVerdictProvider.future);
    await container.read(esimVerdictProvider.future);

    expect(callCount, 1);
  });
}
