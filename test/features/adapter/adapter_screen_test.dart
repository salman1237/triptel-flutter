import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/ccid_providers.dart';
import 'package:triptel/features/adapter/data/ccid_channel.dart';
import 'package:triptel/features/adapter/presentation/adapter_screen.dart';

class _FakeCcidChannel implements CcidChannel {
  _FakeCcidChannel({required bool hasUsbHost})
      : _hasUsbHost = hasUsbHost,
        _controller = StreamController<List<Map<String, dynamic>>>.broadcast();

  final bool _hasUsbHost;
  final StreamController<List<Map<String, dynamic>>> _controller;

  @override
  Future<bool> hasUsbHostFeature() async => _hasUsbHost;

  @override
  Stream<List<Map<String, dynamic>>> watchReaders() => _controller.stream;

  void emit(List<Map<String, dynamic>> readers) => _controller.add(readers);
}

Widget _app(_FakeCcidChannel channel) => ProviderScope(
      overrides: [ccidChannelProvider.overrideWithValue(channel)],
      child: const MaterialApp(home: AdapterScreen()),
    );

void main() {
  group('FR-L910: USB CCID reader detection', () {
    testWidgets('no USB host mode on this device shows the unsupported state',
        (tester) async {
      final channel = _FakeCcidChannel(hasUsbHost: false);
      await tester.pumpWidget(_app(channel));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adapter-unsupported-state')),
          findsOneWidget);
    });

    testWidgets('USB host mode but no reader attached shows the empty state',
        (tester) async {
      final channel = _FakeCcidChannel(hasUsbHost: true);
      await tester.pumpWidget(_app(channel));
      channel.emit(const []);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adapter-no-reader-state')),
          findsOneWidget);
    });

    testWidgets(
        'a real reader shape shows its name, vendor/product ids, and '
        'permission state', (tester) async {
      final channel = _FakeCcidChannel(hasUsbHost: true);
      await tester.pumpWidget(_app(channel));
      channel.emit([
        {
          'id': 2,
          'name': 'EMV Smartcard Reader',
          'vendorId': 11491,
          'productId': 38243,
          'hasPermission': false,
        },
      ]);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adapter-reader-2')), findsOneWidget);
      expect(find.text('EMV Smartcard Reader'), findsOneWidget);
      expect(find.text('Vendor 11491 · Product 38243'), findsOneWidget);
      expect(find.text('Access not granted'), findsOneWidget);
    });

    testWidgets('a granted reader shows "Access granted"', (tester) async {
      final channel = _FakeCcidChannel(hasUsbHost: true);
      await tester.pumpWidget(_app(channel));
      channel.emit([
        {
          'id': 2,
          'name': 'EMV Smartcard Reader',
          'vendorId': 11491,
          'productId': 38243,
          'hasPermission': true,
        },
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Access granted'), findsOneWidget);
    });

    testWidgets(
        'a hot-plug event updates the list live -- detach returns to the '
        'empty state, no restart needed', (tester) async {
      final channel = _FakeCcidChannel(hasUsbHost: true);
      await tester.pumpWidget(_app(channel));
      channel.emit([
        {
          'id': 2,
          'name': 'EMV Smartcard Reader',
          'vendorId': 11491,
          'productId': 38243,
          'hasPermission': false,
        },
      ]);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('adapter-reader-2')), findsOneWidget);

      channel.emit(const []);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adapter-reader-2')), findsNothing);
      expect(find.byKey(const ValueKey('adapter-no-reader-state')),
          findsOneWidget);
    });
  });
}
