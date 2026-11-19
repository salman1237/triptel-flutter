import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/omapi_channel.dart';
import 'omapi_probe_result.dart';

final omapiChannelProvider =
    Provider<OmapiChannel>((ref) => OmapiChannelImpl());

/// FR-L905: runs the native probe once per screen visit (autoDispose --
/// re-running it is a deliberate user action, via `ref.invalidate`, not
/// a background refresh; the probe takes a real device/card round trip).
final omapiProbeProvider =
    FutureProvider.autoDispose<OmapiProbeResult>((ref) async {
  final raw = await ref.watch(omapiChannelProvider).probeUiccSecureElement();
  return OmapiProbeResult.fromRaw(raw);
});
