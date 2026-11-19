import 'package:go_router/go_router.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/account/presentation/profile_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/set_password_screen.dart';
import '../features/auth/presentation/suspended_screen.dart';
import '../features/catalog/presentation/destination_plans_screen.dart';
import '../features/catalog/presentation/home_screen.dart';
import '../features/checkout/presentation/checkout_review_screen.dart';
import '../features/compatibility/presentation/compatibility_result_screen.dart';
import '../features/adapter/presentation/activation_input_screen.dart';
import '../features/adapter/presentation/omapi_probe_screen.dart';
import '../features/compatibility/presentation/supported_devices_screen.dart';
import '../features/esims/presentation/esim_detail_screen.dart';
import '../features/referrals/presentation/refer_earn_screen.dart';
import '../features/esims/presentation/esim_receipt_screen.dart';
import '../features/esims/presentation/my_esims_screen.dart';
import '../features/guides/presentation/esim_setup_guide_screen.dart';
import '../features/kyc/presentation/kyc_screen.dart';
import '../features/legal/presentation/legal_document_screen.dart';
import '../features/legal/presentation/legal_documents_screen.dart';
import '../features/support/presentation/new_ticket_screen.dart';
import '../features/support/presentation/report_problem_screen.dart';
import '../features/support/presentation/support_ticket_list_screen.dart';
import '../features/support/presentation/ticket_thread_screen.dart';
import '../features/tracking/presentation/tracking_screen.dart';
import '../features/wallet/presentation/ledger_screen.dart';
import '../features/wallet/presentation/manual_deposit_screen.dart';
import '../features/wallet/presentation/wallet_screen.dart';
import '../features/wallet/presentation/wallet_topup_screen.dart';
import '../features/withdrawals/presentation/add_payout_account_screen.dart';
import '../features/withdrawals/presentation/payout_accounts_screen.dart';
import '../features/withdrawals/presentation/withdrawal_history_screen.dart';
import '../features/withdrawals/presentation/withdrawal_receipt_screen.dart';
import '../features/withdrawals/presentation/withdrawal_request_screen.dart';
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
    GoRoute(
        path: '/compatibility',
        builder: (context, state) => const CompatibilityResultScreen()),
    GoRoute(
        path: '/compatibility/devices',
        builder: (context, state) => const SupportedDevicesScreen()),
    GoRoute(
        path: '/adapter/omapi-probe',
        builder: (context, state) => const OmapiProbeScreen()),
    GoRoute(
        path: '/adapter/activation-input',
        builder: (context, state) => const ActivationInputScreen()),
    GoRoute(
      path: '/explore/:slug',
      builder: (context, state) =>
          DestinationPlansScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/checkout/review',
      builder: (context, state) =>
          CheckoutReviewScreen(args: state.extra! as CheckoutReviewArgs),
    ),
    GoRoute(
      path: '/my-esims/:id',
      builder: (context, state) =>
          EsimDetailScreen(esimId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/my-esims/:id/print',
      builder: (context, state) =>
          EsimReceiptScreen(esimId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/my-esims/:id/report-problem',
      builder: (context, state) =>
          ReportProblemScreen(args: state.extra! as ReportProblemArgs),
    ),
    GoRoute(
      path: '/wallet/history',
      builder: (context, state) => const LedgerScreen(),
    ),
    GoRoute(
      path: '/wallet/topup',
      builder: (context, state) => const WalletTopupScreen(),
    ),
    GoRoute(
      path: '/wallet/manual-deposit',
      builder: (context, state) => const ManualDepositScreen(),
    ),
    GoRoute(
      path: '/wallet/withdraw',
      builder: (context, state) => const WithdrawalRequestScreen(),
    ),
    GoRoute(
      path: '/wallet/withdraw/accounts',
      builder: (context, state) => const PayoutAccountsScreen(),
    ),
    GoRoute(
      path: '/wallet/withdraw/accounts/add',
      builder: (context, state) => const AddPayoutAccountScreen(),
    ),
    GoRoute(
      path: '/wallet/withdraw/history',
      builder: (context, state) => const WithdrawalHistoryScreen(),
    ),
    GoRoute(
      path: '/wallet/withdraw/:id/receipt',
      builder: (context, state) =>
          WithdrawalReceiptScreen(withdrawalId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/refer',
      builder: (context, state) => const ReferEarnScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/kyc',
      builder: (context, state) => const KycScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportTicketListScreen(),
    ),
    GoRoute(
      path: '/support/new',
      builder: (context, state) => const NewTicketScreen(),
    ),
    GoRoute(
      path: '/support/:id',
      builder: (context, state) =>
          TicketThreadScreen(ticketId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/guides/esim-setup-guide',
      builder: (context, state) => const EsimSetupGuideScreen(),
    ),
    GoRoute(
      path: '/legal',
      builder: (context, state) => const LegalDocumentsScreen(),
    ),
    GoRoute(
      path: '/legal/:slug',
      builder: (context, state) =>
          LegalDocumentScreen(slug: state.pathParameters['slug']!),
    ),
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
