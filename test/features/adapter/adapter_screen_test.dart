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
  _FakeCcidChannel({
    required bool hasUsbHost,
    Map<String, dynamic>? permissionResult,
    Map<String, dynamic>? powerOnResult,
    Map<String, dynamic>? selectIsdRResult,
    Map<String, dynamic>? readEidResult,
    Map<String, dynamic>? readEuiccInfo2Result,
  })  : _hasUsbHost = hasUsbHost,
        _permissionResult = permissionResult ?? const {'result': 'granted'},
        _powerOnResult = powerOnResult ?? const {'outcome': 'success'},
        _selectIsdRResult = selectIsdRResult ?? const {'outcome': 'success'},
        _readEidResult = readEidResult ?? const {'outcome': 'success'},
        _readEuiccInfo2Result =
            readEuiccInfo2Result ?? const {'outcome': 'success'};

  final bool _hasUsbHost;
  final Map<String, dynamic> _permissionResult;
  final Map<String, dynamic> _powerOnResult;
  final Map<String, dynamic> _selectIsdRResult;
  final Map<String, dynamic> _readEidResult;
  final Map<String, dynamic> _readEuiccInfo2Result;
  List<Map<String, dynamic>> _current = const [];
  final _watchers = <StreamController<List<Map<String, dynamic>>>>[];
  int requestPermissionCalls = 0;
  int? lastRequestedDeviceId;
  int powerOnCalls = 0;
  int? lastPowerOnDeviceId;
  int selectIsdRCalls = 0;
  int? lastSelectIsdRDeviceId;
  int readEidCalls = 0;
  int? lastReadEidDeviceId;
  int readEuiccInfo2Calls = 0;
  int? lastReadEuiccInfo2DeviceId;

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

  @override
  Future<Map<String, dynamic>> powerOn(int deviceId) async {
    powerOnCalls++;
    lastPowerOnDeviceId = deviceId;
    return _powerOnResult;
  }

  @override
  Future<Map<String, dynamic>> selectIsdR(int deviceId) async {
    selectIsdRCalls++;
    lastSelectIsdRDeviceId = deviceId;
    return _selectIsdRResult;
  }

  @override
  Future<Map<String, dynamic>> readEid(int deviceId) async {
    readEidCalls++;
    lastReadEidDeviceId = deviceId;
    return _readEidResult;
  }

  @override
  Future<Map<String, dynamic>> readEuiccInfo2(int deviceId) async {
    readEuiccInfo2Calls++;
    lastReadEuiccInfo2DeviceId = deviceId;
    return _readEuiccInfo2Result;
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

  group('FR-L912: power on the card', () {
    testWidgets(
        'a granted reader shows a "Power on" button, no result shown yet',
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

      expect(find.byKey(const ValueKey('adapter-reader-2-power-on-button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('adapter-reader-2-power-on-result')),
          findsNothing);
    });

    testWidgets('an ungranted reader shows no "Power on" button',
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

      expect(find.byKey(const ValueKey('adapter-reader-2-power-on-button')),
          findsNothing);
    });

    testWidgets(
        'a successful power-on shows the real ATR, protocols, and voltage',
        (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        powerOnResult: const {
          'outcome': 'success',
          'atrHex': '3B9F96801FC78031E073FE211B64D0009000FA',
          'protocols': [0, 1],
          'preferredProtocol': 1,
          'checksumValid': true,
          'voltage': 'V5_0',
        },
      );
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

      final button =
          find.byKey(const ValueKey('adapter-reader-2-power-on-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(channel.powerOnCalls, 1);
      expect(channel.lastPowerOnDeviceId, 2);
      expect(
          find.text('3B9F96801FC78031E073FE211B64D0009000FA'), findsOneWidget);
      expect(find.textContaining('T=1'), findsOneWidget);
      expect(find.textContaining('V5_0'), findsOneWidget);
    });

    testWidgets('a power-on failure shows the real native reason',
        (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        powerOnResult: const {
          'outcome': 'power_on_failed',
          'reason': 'ICC_MUTE: no response from the card (not inserted, or '
              'dead)',
          'error': 0xFE,
        },
      );
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

      final button =
          find.byKey(const ValueKey('adapter-reader-2-power-on-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.textContaining('ICC_MUTE'), findsOneWidget);
    });
  });

  group('FR-L913: select ISD-R', () {
    testWidgets('no "Select ISD-R" button before a successful power-on',
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

      expect(find.byKey(const ValueKey('adapter-reader-2-select-isdr-button')),
          findsNothing);
    });

    testWidgets(
        'after a successful power-on, tapping "Select ISD-R" shows the '
        'real status word and FCI', (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        selectIsdRResult: const {
          'outcome': 'success',
          'channel': 1,
          'sw': '9000',
          'success': true,
          'fciHex': '6F108408A000000559101001A5049F6501FF',
        },
      );
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

      final powerOnButton =
          find.byKey(const ValueKey('adapter-reader-2-power-on-button'));
      await tester.ensureVisible(powerOnButton);
      await tester.tap(powerOnButton);
      await tester.pumpAndSettle();

      final selectButton =
          find.byKey(const ValueKey('adapter-reader-2-select-isdr-button'));
      await tester.ensureVisible(selectButton);
      await tester.tap(selectButton);
      await tester.pumpAndSettle();

      expect(channel.selectIsdRCalls, 1);
      expect(channel.lastSelectIsdRDeviceId, 2);
      expect(find.textContaining('9000'), findsOneWidget);
      expect(find.text('6F108408A000000559101001A5049F6501FF'), findsOneWidget);
    });

    testWidgets('a channel_open_failed result shows the real native reason',
        (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        selectIsdRResult: const {
          'outcome': 'channel_open_failed',
          'reason': 'SW=6e00',
        },
      );
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

      final powerOnButton =
          find.byKey(const ValueKey('adapter-reader-2-power-on-button'));
      await tester.ensureVisible(powerOnButton);
      await tester.tap(powerOnButton);
      await tester.pumpAndSettle();

      final selectButton =
          find.byKey(const ValueKey('adapter-reader-2-select-isdr-button'));
      await tester.ensureVisible(selectButton);
      await tester.tap(selectButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('6e00'), findsOneWidget);
    });
  });

  group('FR-L914: read EID', () {
    Future<void> powerOnReader(WidgetTester tester) async {
      final powerOnButton =
          find.byKey(const ValueKey('adapter-reader-2-power-on-button'));
      await tester.ensureVisible(powerOnButton);
      await tester.tap(powerOnButton);
      await tester.pumpAndSettle();
    }

    testWidgets('no "Read EID" button before a successful power-on',
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

      expect(find.byKey(const ValueKey('adapter-reader-2-read-eid-button')),
          findsNothing);
    });

    testWidgets(
        'after power-on, tapping "Read EID" shows the real EID masked by '
        'default', (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        readEidResult: const {
          'outcome': 'success',
          'eid': '89086030000000000135090432000000',
        },
      );
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
      await powerOnReader(tester);

      final readButton =
          find.byKey(const ValueKey('adapter-reader-2-read-eid-button'));
      await tester.ensureVisible(readButton);
      await tester.tap(readButton);
      await tester.pumpAndSettle();

      expect(channel.readEidCalls, 1);
      expect(channel.lastReadEidDeviceId, 2);
      // Masked: only the last 4 real digits visible, never the full EID.
      expect(find.text('89086030000000000135090432000000'), findsNothing);
      expect(find.textContaining('0000'), findsOneWidget);
    });

    testWidgets('tapping the reveal toggle shows the real, unmasked EID',
        (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        readEidResult: const {
          'outcome': 'success',
          'eid': '89086030000000000135090432000000',
        },
      );
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
      await powerOnReader(tester);

      final readButton =
          find.byKey(const ValueKey('adapter-reader-2-read-eid-button'));
      await tester.ensureVisible(readButton);
      await tester.tap(readButton);
      await tester.pumpAndSettle();

      final revealToggle =
          find.byKey(const ValueKey('adapter-eid-reveal-toggle'));
      await tester.ensureVisible(revealToggle);
      await tester.tap(revealToggle);
      await tester.pumpAndSettle();

      expect(find.text('89086030000000000135090432000000'), findsOneWidget);
    });

    testWidgets('a read_failed result shows a clear message, never crashes',
        (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        readEidResult: const {'outcome': 'read_failed'},
      );
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
      await powerOnReader(tester);

      final readButton =
          find.byKey(const ValueKey('adapter-reader-2-read-eid-button'));
      await tester.ensureVisible(readButton);
      await tester.tap(readButton);
      await tester.pumpAndSettle();

      expect(find.text("Couldn't read the EID."), findsOneWidget);
    });
  });

  group('FR-L915: chip info', () {
    Future<void> powerOnReader(WidgetTester tester) async {
      final powerOnButton =
          find.byKey(const ValueKey('adapter-reader-2-power-on-button'));
      await tester.ensureVisible(powerOnButton);
      await tester.tap(powerOnButton);
      await tester.pumpAndSettle();
    }

    testWidgets('no "Chip info" button before a successful power-on',
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

      expect(find.byKey(const ValueKey('adapter-reader-2-chip-info-button')),
          findsNothing);
    });

    testWidgets(
        'after power-on, tapping "Chip info" shows the real SGP.22 '
        'version and free memory', (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        readEuiccInfo2Result: const {
          'outcome': 'success',
          'svn': '2.2.0',
          'freeNonVolatileMemory': 427416,
          'freeVolatileMemory': 12544,
        },
      );
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
      await powerOnReader(tester);

      final chipInfoButton =
          find.byKey(const ValueKey('adapter-reader-2-chip-info-button'));
      await tester.ensureVisible(chipInfoButton);
      await tester.tap(chipInfoButton);
      await tester.pumpAndSettle();

      expect(channel.readEuiccInfo2Calls, 1);
      expect(channel.lastReadEuiccInfo2DeviceId, 2);
      expect(find.textContaining('2.2.0'), findsOneWidget);
      expect(find.textContaining('417.4 KB'), findsOneWidget);
    });

    testWidgets(
        'a detached (unplugged mid-read) result shows a distinct '
        'message, never crashes', (tester) async {
      final channel = _FakeCcidChannel(
        hasUsbHost: true,
        readEuiccInfo2Result: const {'outcome': 'detached'},
      );
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
      await powerOnReader(tester);

      final chipInfoButton =
          find.byKey(const ValueKey('adapter-reader-2-chip-info-button'));
      await tester.ensureVisible(chipInfoButton);
      await tester.tap(chipInfoButton);
      await tester.pumpAndSettle();

      expect(find.text('The reader was unplugged mid-read.'), findsOneWidget);
    });
  });
}
