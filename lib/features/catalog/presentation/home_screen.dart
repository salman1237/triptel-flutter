import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';

/// Home tab placeholder. Real content (hero, quick actions, promos) lands in
/// FR-201; this just proves the FR-004 shell routes here.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('home-tab'),
      body: const EmptyState(
        icon: Icons.explore_outlined,
        message: 'Home — destinations and plans are coming in FR-201.',
      ),
    );
  }
}
