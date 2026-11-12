import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';

/// Public order tracking placeholder — `/track/:token` routes here from
/// FR-007's deep link handling. Real lookup via the tracking token lands in
/// FR-501; this just proves the link is parsed and routed correctly.
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('tracking-screen'),
      body: EmptyState(
        icon: Icons.local_shipping_outlined,
        message: 'Tracking "$token" — order lookup is coming in FR-501.',
      ),
    );
  }
}
