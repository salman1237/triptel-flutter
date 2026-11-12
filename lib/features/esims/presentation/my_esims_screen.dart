import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';

/// My eSIMs tab placeholder. Real list/status lands in FR-402.
class MyEsimsScreen extends StatelessWidget {
  const MyEsimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('my-esims-tab'),
      body: const EmptyState(
        icon: Icons.sim_card_outlined,
        message: 'My eSIMs — your purchased eSIMs are coming in FR-402.',
      ),
    );
  }
}
