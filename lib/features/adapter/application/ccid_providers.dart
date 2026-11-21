import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ccid_channel.dart';
import 'ccid_reader.dart';

final ccidChannelProvider = Provider<CcidChannel>((ref) => CcidChannelImpl());

/// FR-L910: whether this device has USB host mode at all. A one-shot
/// check (doesn't change at runtime), separate from the live reader
/// stream so the UI can show a clear "not supported on this device"
/// state instead of an empty-forever reader list.
final ccidHasUsbHostProvider = FutureProvider<bool>(
  (ref) => ref.watch(ccidChannelProvider).hasUsbHostFeature(),
);

/// FR-L910: the live list of attached CCID readers, updated on every
/// attach/detach while the app is foregrounded.
final ccidReadersProvider = StreamProvider<List<CcidReader>>(
  (ref) =>
      ref.watch(ccidChannelProvider).watchReaders().map(CcidReader.fromRawList),
);
