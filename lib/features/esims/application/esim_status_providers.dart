import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/esim_status_api.dart';
import '../data/models/esim_status.dart';

final esimStatusApiProvider = Provider<EsimStatusApi>(
  (ref) => EsimStatusApiImpl(ref.watch(apiClientProvider)),
);

/// FR-403: one eSIM's status, keyed by id. Manual refresh (with its 30s
/// cooldown) is handled by the detail screen itself, not this provider --
/// `ref.invalidate` + re-await `.future` re-fetches the same way FR-402's
/// list does.
final esimStatusProvider =
    FutureProvider.family<EsimStatus, String>((ref, esimId) {
  return ref.watch(esimStatusApiProvider).getStatus(esimId);
});
