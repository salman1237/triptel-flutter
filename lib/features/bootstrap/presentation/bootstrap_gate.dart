import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/widgets.dart';
import '../application/bootstrap_providers.dart';
import 'maintenance_screen.dart';
import 'splash_screen.dart';

/// Root widget: splash while bootstrap loads, blocking [MaintenanceScreen]
/// when `maintenance_mode`, otherwise [child] (FR-002/FR-003).
class BootstrapGate extends ConsumerWidget {
  const BootstrapGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapProvider);

    return bootstrap.when(
      loading: () => const SplashScreen(),
      error: (error, stack) => Scaffold(
        body: Center(
          child: ErrorState(
            message: "Couldn't reach Triptel. Check your connection and retry.",
            onRetry: () => ref.invalidate(bootstrapProvider),
          ),
        ),
      ),
      data: (data) => data.settings.maintenanceMode
          ? MaintenanceScreen(
              settings: data.settings,
              onRetry: () => ref.invalidate(bootstrapProvider),
            )
          : child,
    );
  }
}
