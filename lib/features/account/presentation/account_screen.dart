import 'package:flutter/material.dart';
import '../../../core/i18n/language_pill_switcher.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Account tab placeholder. Real greeting card/grouped list lands in FR-1001;
/// hosts FR-006's language pill until then (account/settings owns it).
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('account-tab'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: AppSpacing.gutter),
          const LanguagePillSwitcher(),
          const EmptyState(
            icon: Icons.person_outline,
            message: 'Account — profile and settings are coming in FR-1001.',
          ),
        ],
      ),
    );
  }
}
