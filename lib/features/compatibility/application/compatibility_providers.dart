import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/esim_support_channel.dart';
import 'esim_verdict.dart';

final esimSupportChannelProvider =
    Provider<EsimSupportChannel>((ref) => EsimSupportChannelImpl());

/// FR-953: the verdict is cached for the app session (a `keepAlive` provider
/// reused by the compatibility screen, the checkout gate, and install
/// buttons) rather than re-queried on every read.
final esimVerdictProvider = FutureProvider<EsimVerdict>((ref) async {
  final signals = await ref.watch(esimSupportChannelProvider).getSignals();
  return evaluateEsimSupport(signals);
});
