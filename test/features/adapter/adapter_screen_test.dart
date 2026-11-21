import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/ccid_providers.dart';
import 'package:triptel/features/adapter/data/ccid_channel.dart';
import 'package:triptel/features/adapter/presentation/adapter_screen.dart';

/// Models the real native shape: [watchReaders] only emits on a fresh
/// subscription (`onListen`) or a real hot-plug broadcast ([emit]) --
/// never as a side effect of [requestPermission]. A granted permission
/// updates the underlying state but is only ever observed by a *new*
/// subscription, exactly like the real `UsbCcidReaders.kt` (a
/// permission grant doesn't fire `ACTION_USB_DEVICE_ATTACHED`/
/// `DETACHED`, so nothing re-triggers `emitCurrentList()` on its own --
/// the screen must call `ref.invalidate(ccidReadersProvider)` to see
/// it). This is deliberate: it's what makes the "granted" test below
/// actually exercise that invalidate call, not just redundantly re-emit.
class _FakeCcidChannel implements CcidChannel {
  _FakeCcidChannel(
      {required bool hasUsbHost, Map<String, dynamic>? permissionResult})
      : _hasUsbHost = hasUsbHost,
        _permissionResult = permissionResult ?? const {'result': 'granted'};

  final bool _hasUsbHost;
  final Map<String, dynamic> _permissionResult;
  List<Map<String, dynamic>> _current = const [];
  final _watchers = <StreamController<List<Map<String, dynamic>>>>[];
  int requestPermissionCalls = 0;
  int? lastRequestedDeviceId;

  @override
  Future<bool> hasUsbHostFeature() async => _hasUsbHost;

  @override
  Stream<List<Map<String, dynamic>>> watchReaders() {
    late StreamController<List<Map<String, dynamic>>> controller;
    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () => controller.add(_current),
      onCancel: () => _watchers.remove(controller),
    );
    _watchers.add(controller);
    return controller.stream;
  }

  @override
  Future<Map<String, dynamic>> requestPermission(int deviceId) async {
    requestPermissionCalls++;
    lastRequestedDeviceId = deviceId;
    if (_permissionResult['result'] == 'granted') {
      _current = _current
          .map((r) => r['id'] == deviceId ? {...r, 'hasPermission': true} : r)
          .toList();
    }
    return _permissionResult;
  }

  /// Simulates a real hot-plug broadcast (attach/detach) -- delivered to
  /// whatever's currently subscribed.
  void emit(List<Map<String, dynamic>> readers) {
    _current = readers;
    for (final c in List.of(_watchers)) {
      c.add(readers);
    }
  }
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

  group('FR-L911: USB permission request', () {
    testWidgets('an ungranted reader shows a "Grant access" button',
        (tester) async {
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

      expect(find.byKey(const ValueKey('adapter-reader-2-grant-button')),
          findsOneWidget);
    });

    testWidgets('a granted reader shows no "Grant access" button',
        (tester) async {
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

      expect(find.byKey(const ValueKey('adapter-reader-2-grant-button')),
          findsNothing);
    });

    testWidgets(
        'tapping "Grant access" requests permission for the real device id, '
        'and a granted result refreshes the reader list', (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        permissionResult: const {'result': 'granted'},
      );
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

      final button =
          find.byKey(const ValueKey('adapter-reader-2-grant-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(channel.requestPermissionCalls, 1);
      expect(channel.lastRequestedDeviceId, 2);

      expect(find.text('Access granted'), findsOneWidget);
      expect(find.byKey(const ValueKey('adapter-reader-2-grant-button')),
          findsNothing);
    });

    testWidgets('a denied result shows a clear, retryable message',
        (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        permissionResult: const {'result': 'denied'},
      );
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

      final button =
          find.byKey(const ValueKey('adapter-reader-2-grant-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.textContaining('Permission denied'), findsOneWidget);
      // Still retryable -- the button is still there.
      expect(find.byKey(const ValueKey('adapter-reader-2-grant-button')),
          findsOneWidget);
    });

    testWidgets(
        'a detached-meanwhile result shows a distinct message, never '
        'crashes', (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        permissionResult: const {'result': 'detached_meanwhile'},
      );
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

      final button =
          find.byKey(const ValueKey('adapter-reader-2-grant-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.textContaining('unplugged before you responded'),
          findsOneWidget);
    });
  });
}
