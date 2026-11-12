import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/deep_link_bridge.dart';
import 'app/router.dart';
import 'core/i18n/rtl_scope.dart';
import 'core/theme/theme.dart';
import 'features/bootstrap/presentation/bootstrap_gate.dart';

void main() {
  runApp(const ProviderScope(child: TriptelApp()));
}

class TriptelApp extends StatelessWidget {
  const TriptelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Triptel',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
      builder: (context, child) => DeepLinkBridge(
        child: BootstrapGate(
          child: RtlScope(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
