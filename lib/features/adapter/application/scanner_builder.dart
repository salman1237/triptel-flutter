import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// FR-L902: builds the live QR camera widget -- a seam so widget tests
/// can swap in a stub instead of the real camera (which needs a device
/// and a running platform channel the test harness doesn't provide).
/// [onCode] fires with the raw decoded text on a successful scan;
/// [onError] fires on a camera/permission error (e.g. denied), which is
/// a normal state here -- the other three input sources stay available.
typedef ScannerBuilder = Widget Function(
  void Function(String rawValue) onCode,
  void Function() onError,
);

final scannerBuilderProvider = Provider<ScannerBuilder>(
  (ref) => (onCode, onError) => MobileScanner(
        onDetect: (capture) {
          if (capture.barcodes.isEmpty) return;
          final value = capture.barcodes.first.rawValue;
          if (value != null) onCode(value);
        },
        onDetectError: (error, stackTrace) => onError(),
      ),
);
