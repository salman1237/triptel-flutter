import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/wallets_api.dart';

final walletsApiProvider = Provider<WalletsApi>(
  (ref) => WalletsApiImpl(ref.watch(apiClientProvider)),
);
