import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/language_pill_switcher.dart';
import '../../../core/money/currency_format.dart';
import '../../../core/money/currency_pill_switcher.dart';
import '../../../core/money/currency_providers.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../../auth/data/models/auth_token.dart';
import '../../kyc/application/kyc_providers.dart';
import '../../kyc/application/kyc_status_label.dart';
import '../../support/presentation/contact_shortcuts_sheet.dart';
import '../../wallet/application/wallet_balance.dart';
import '../../wallet/application/wallet_providers.dart';
import '../application/app_version_provider.dart';
import '../application/track_input.dart';

/// FR-1001: Eskimo Account pattern -- greeting card (name, wallet balance,
/// reward credit) + Invite CTA, then grouped rows (Account/Settings/
/// Support/About), Sign out. Profile -> FR-1002's real screen, Identity
/// verification -> FR-1003's real screen, Help/Support tickets ->
/// FR-1101's real screen, Contact us -> FR-1104's WhatsApp/phone/email
/// shortcuts sheet, Legal documents -> FR-1201's real list/reader.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _showTrackDialog(BuildContext context) async {
    final controller = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Track an eSIM'),
        content: TextField(
          key: const ValueKey('track-esim-field'),
          controller: controller,
          decoration: const InputDecoration(
              labelText: 'Tracking link or token',
              hintText: 'triptel.co/track/...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('track-esim-submit'),
            onPressed: () => Navigator.of(dialogContext)
                .pop(resolveTrackingToken(controller.text)),
            child: const Text('Track'),
          ),
        ],
      ),
    );
    if (token != null && context.mounted) context.push('/track/$token');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);

    return TriptelScaffold(
      key: const ValueKey('account-tab'),
      body: switch (auth.value) {
        AuthAuthenticated(token: final token) =>
          _AuthedBody(token: token, onTrack: () => _showTrackDialog(context)),
        _ => Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.gutter),
                const Align(
                  alignment: Alignment.centerRight,
                  child: LanguagePillSwitcher(),
                ),
                const SizedBox(height: 16),
                const EmptyState(
                  icon: Icons.person_outline,
                  message: 'Sign in to manage your account, wallet, and '
                      'eSIMs.',
                ),
                const SizedBox(height: 16),
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
    );
  }
}

class _AuthedBody extends ConsumerWidget {
  const _AuthedBody({required this.token, required this.onTrack});

  final AuthToken token;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(myWalletsProvider);
    final rate = ref.watch(selectedCurrencyRateProvider).valueOrNull;
    final code = ref.watch(currencyPreferenceProvider).valueOrNull;
    final kycAsync = ref.watch(kycStatusProvider);
    final versionAsync = ref.watch(appVersionProvider);

    String money(Money amount) => rate == null || code == null
        ? ''
        : formatMoney(amount, currencyCode: code, rateToBase: rate);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (walletsAsync) {
            AsyncData(:final value) => BalanceCard(
                key: const ValueKey('account-greeting-card'),
                title: 'Hello, ${token.username}!',
                amountText: money(walletBalance(value, 'DEFAULT')),
                stats: [
                  ('Reward credit', money(walletBalance(value, 'REWARD'))),
                ],
              ),
            _ => BalanceCard(
                key: const ValueKey('account-greeting-card'),
                title: 'Hello, ${token.username}!',
                amountText: '',
              ),
          },
          const SizedBox(height: 12),
          PillButton(
            key: const ValueKey('account-invite-button'),
            label: 'Invite friends',
            onPressed: () => context.push('/refer'),
          ),
          if (token.mustChangePassword) ...[
            const SizedBox(height: 16),
            InfoBox(
              key: const ValueKey('must-change-password-prompt'),
              icon: Icons.lock_outline,
              text: "You're using a temporary password. Set your own to "
                  'buy eSIMs or move money.',
            ),
            const SizedBox(height: 12),
            PillButton(
              label: 'Set password',
              onPressed: () => context.go('/set-password'),
            ),
          ],
          const SizedBox(height: 24),
          Text('Account',
              style: AppTypography.label(color: AppColors.inkMuted)),
          const SizedBox(height: 8),
          ListGroup(
            children: [
              ListRow(
                key: const ValueKey('account-profile-row'),
                icon: Icons.person_outline,
                title: 'Profile',
                onTap: () => context.push('/profile'),
              ),
              ListRow(
                key: const ValueKey('account-kyc-row'),
                icon: Icons.verified_user_outlined,
                title: 'Identity verification',
                subtitle: switch (kycAsync) {
                  AsyncData(:final value) => kycStatusLabel(value).label,
                  AsyncError() => 'Unavailable',
                  _ => null,
                },
                subtitleColor: switch (kycAsync) {
                  AsyncData(:final value) => kycStatusLabel(value).color,
                  _ => null,
                },
                onTap: () => context.push('/kyc'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Settings',
              style: AppTypography.label(color: AppColors.inkMuted)),
          const SizedBox(height: 8),
          ListGroup(
            children: [
              _SwitcherRow(
                icon: Icons.language,
                title: 'Language',
                switcher: const LanguagePillSwitcher(),
              ),
              _SwitcherRow(
                icon: Icons.attach_money,
                title: 'Currency',
                switcher: const CurrencyPillSwitcher(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Support',
              style: AppTypography.label(color: AppColors.inkMuted)),
          const SizedBox(height: 8),
          ListGroup(
            children: [
              ListRow(
                key: const ValueKey('account-compatibility-row'),
                icon: Icons.phone_iphone_outlined,
                title: 'Check device compatibility',
                onTap: () => context.push('/compatibility/devices'),
              ),
              ListRow(
                key: const ValueKey('account-setup-guide-row'),
                icon: Icons.menu_book_outlined,
                title: 'Setup guide',
                onTap: () => context.push('/guides/esim-setup-guide'),
              ),
              ListRow(
                key: const ValueKey('account-support-row'),
                icon: Icons.support_agent_outlined,
                title: 'Help / Support tickets',
                onTap: () => context.push('/support'),
              ),
              ListRow(
                key: const ValueKey('account-contact-row'),
                icon: Icons.contact_support_outlined,
                title: 'Contact us',
                onTap: () => showContactShortcutsSheet(context),
              ),
              ListRow(
                key: const ValueKey('account-track-row'),
                icon: Icons.location_searching,
                title: 'Track an eSIM',
                onTap: onTrack,
              ),
              // FR-L905: Android-only diagnostic (OMAPI/USB adapter
              // hardware doesn't exist on iOS) -- never shown there.
              if (Platform.isAndroid) ...[
                ListRow(
                  key: const ValueKey('account-adapter-diagnostic-row'),
                  icon: Icons.sim_card_outlined,
                  title: 'eSIM adapter diagnostic',
                  onTap: () => context.push('/adapter/omapi-probe'),
                ),
                ListRow(
                  key: const ValueKey('account-adapter-activation-input-row'),
                  icon: Icons.qr_code_scanner,
                  title: 'Add eSIM via adapter',
                  onTap: () => context.push('/adapter/activation-input'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text('About', style: AppTypography.label(color: AppColors.inkMuted)),
          const SizedBox(height: 8),
          ListGroup(
            children: [
              ListRow(
                key: const ValueKey('account-legal-row'),
                icon: Icons.description_outlined,
                title: 'Legal documents',
                onTap: () => context.push('/legal'),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text('Version', style: AppTypography.body())),
                    switch (versionAsync) {
                      AsyncData(:final value) => Text(value,
                          key: const ValueKey('account-version'),
                          style:
                              AppTypography.caption(color: AppColors.inkMuted)),
                      _ => const SizedBox.shrink(),
                    },
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PillButton(
            key: const ValueKey('account-sign-out-button'),
            label: 'Sign out',
            variant: PillButtonVariant.secondary,
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _SwitcherRow extends StatelessWidget {
  const _SwitcherRow({
    required this.icon,
    required this.title,
    required this.switcher,
  });

  final IconData icon;
  final String title;
  final Widget switcher;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: AppTypography.body())),
          switcher,
        ],
      ),
    );
  }
}
