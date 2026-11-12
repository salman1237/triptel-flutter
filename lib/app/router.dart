import 'package:go_router/go_router.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/catalog/presentation/home_screen.dart';
import '../features/esims/presentation/my_esims_screen.dart';
import '../features/wallet/presentation/wallet_screen.dart';
import 'app_shell.dart';

/// FR-004's 4-tab shell, one branch per tab so each keeps its own navigation
/// stack (Architecture.md: `go_router` `StatefulShellRoute`).
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/home', builder: (context, state) => const HomeScreen())
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/my-esims',
                builder: (context, state) => const MyEsimsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletScreen())
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/account',
                builder: (context, state) => const AccountScreen())
          ],
        ),
      ],
    ),
  ],
);
