import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme_preview_screen.dart';
import 'core/theme/theme.dart';

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
      // TODO(FR-002/FR-004): replace with the bootstrap + go_router shell.
      home: const ThemePreviewScreen(),
    );
  }
}
