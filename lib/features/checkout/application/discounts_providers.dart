import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/discounts_api.dart';

final discountsApiProvider = Provider<DiscountsApi>(
  (ref) => DiscountsApiImpl(ref.watch(apiClientProvider)),
);
