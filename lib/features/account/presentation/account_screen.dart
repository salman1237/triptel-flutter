import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/language_pill_switcher.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';

/// Account tab placeholder. Real greeting card/grouped list lands in FR-1001;
/// hosts FR-006's language pill and, until FR-102/FR-1001 land, the
/// register entry point so FR-101 is actually reachable in the app.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);

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
          const SizedBox(height: 16),
          switch (auth.value) {
            AuthAuthenticated(token: final token) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Signed in as ${token.username}',
                      key: const ValueKey('signed-in-label'),
                      textAlign: TextAlign.center,
                      style: AppTypography.body(),
                    ),
                    if (token.mustChangePassword) ...[
                      const SizedBox(height: 12),
                      InfoBox(
                        key: const ValueKey('must-change-password-prompt'),
                        icon: Icons.lock_outline,
                        text:
                            "You're using a temporary password. Set your own to buy eSIMs or"
                            ' move money.',
                      ),
                      const SizedBox(height: 12),
                      PillButton(
                        label: 'Set password',
                        onPressed: () => context.go('/set-password'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    PillButton(
                      label: 'Sign out',
                      variant: PillButtonVariant.secondary,
                      onPressed: () =>
                          ref.read(authNotifierProvider.notifier).logout(),
                    ),
                  ],
                ),
              ),
            _ => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PillButton(
                      label: 'Create account',
                      onPressed: () => context.go('/register'),
                    ),
                    const SizedBox(height: 12),
                    PillButton(
                      label: 'Sign in',
                      variant: PillButtonVariant.secondary,
                      onPressed: () => context.go('/login'),
                    ),
                  ],
                ),
              ),
          },
        ],
      ),
    );
  }
}
