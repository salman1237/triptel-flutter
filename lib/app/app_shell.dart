import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';

/// FR-004: 4-tab shell (Home · My eSIMs · Wallet · Account). Refer lives
/// inside Wallet/Account; Support inside Account — no separate tabs for them.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: 'Home'),
    (
      icon: Icons.sim_card_outlined,
      selectedIcon: Icons.sim_card,
      label: 'My eSIMs'
    ),
    (
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Wallet'
    ),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('app-shell'),
      body: navigationShell,
      bottomNavigationBar: ColoredBox(
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      icon: _tabs[i].icon,
                      selectedIcon: _tabs[i].selectedIcon,
                      label: _tabs[i].label,
                      selected: navigationShell.currentIndex == i,
                      onTap: () => navigationShell.goBranch(
                        i,
                        initialLocation: i == navigationShell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.inkMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? selectedIcon : icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption(color: color)),
        ],
      ),
    );
  }
}
