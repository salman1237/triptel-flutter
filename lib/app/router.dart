import 'package:go_router/go_router.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/set_password_screen.dart';
import '../features/auth/presentation/suspended_screen.dart';
import '../features/catalog/presentation/home_screen.dart';
import '../features/esims/presentation/my_esims_screen.dart';
import '../features/tracking/presentation/tracking_screen.dart';
import '../features/wallet/presentation/wallet_screen.dart';
import 'app_shell.dart';

/// FR-004's 4-tab shell, one branch per tab so each keeps its own navigation
/// stack (Architecture.md: `go_router` `StatefulShellRoute`). The top-level
/// `/track/:token` route is FR-007's deep-link target.
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/track/:token',
      builder: (context, state) =>
          TrackingScreen(token: state.pathParameters['token']!),
    ),
    GoRoute(
        path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen()),
    GoRoute(
        path: '/set-password',
        builder: (context, state) => const SetPasswordScreen()),
    GoRoute(
        path: '/suspended',
        builder: (context, state) => const SuspendedScreen()),
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
