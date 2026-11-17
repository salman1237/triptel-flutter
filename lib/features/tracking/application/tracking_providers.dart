import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../../esims/data/models/esim_status.dart';
import '../data/tracking_api.dart';

final trackingApiProvider = Provider<TrackingApi>(
  (ref) => TrackingApiImpl(ref.watch(apiClientProvider)),
);

/// FR-501: one eSIM's public status, keyed by the tracking token.
final publicEsimStatusProvider =
    FutureProvider.family<EsimStatus, String>((ref, token) {
  return ref.watch(trackingApiProvider).getPublicStatus(token);
});
