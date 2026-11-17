import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/kyc_api.dart';
import '../data/models/kyc_status.dart';

final kycApiProvider = Provider<KycApi>(
  (ref) => KycApiImpl(ref.watch(apiClientProvider)),
);

/// FR-1001's Account screen shows this read-only; FR-1003's KycScreen
/// does the same read plus the submission flow.
final kycStatusProvider = FutureProvider<KycStatus>((ref) {
  return ref.watch(kycApiProvider).getMe();
});
