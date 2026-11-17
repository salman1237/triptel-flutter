import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../data/support_api.dart';

final supportApiProvider = Provider<SupportApi>(
  (ref) => SupportApiImpl(ref.watch(apiClientProvider)),
);
