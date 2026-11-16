import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/models/my_esim.dart';
import '../data/my_esims_api.dart';

final myEsimsApiProvider = Provider<MyEsimsApi>(
  (ref) => MyEsimsApiImpl(ref.watch(apiClientProvider)),
);

/// FR-402: the My eSIMs list. A plain `FutureProvider` -- pull-to-refresh
/// calls `ref.invalidate` then awaits `.future` again, same as any other
/// list screen in this app.
final myEsimsProvider = FutureProvider<List<MyEsim>>(
  (ref) => ref.watch(myEsimsApiProvider).getMyEsims(),
);
