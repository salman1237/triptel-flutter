import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';

/// Account tab placeholder. Real greeting card/grouped list lands in FR-1001.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('account-tab'),
      body: const EmptyState(
        icon: Icons.person_outline,
        message: 'Account — profile and settings are coming in FR-1001.',
      ),
    );
  }
}
