import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme_preview_screen.dart';
import 'core/theme/theme.dart';
import 'features/bootstrap/presentation/bootstrap_gate.dart';

void main() {
  runApp(const ProviderScope(child: TriptelApp()));
}

class TriptelApp extends StatelessWidget {
  const TriptelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triptel',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // TODO(FR-004): replace the preview-screen child with the real 4-tab shell.
      home: const BootstrapGate(child: ThemePreviewScreen()),
    );
  }
}
