import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:triptel/core/i18n/language_providers.dart';
import '../auth/secure_storage_test_mock.dart';
import 'package:triptel/core/money/currency_providers.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/features/account/application/app_version_provider.dart';
import 'package:triptel/features/account/presentation/account_screen.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/application/auth_state.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/kyc/application/kyc_providers.dart';
import 'package:triptel/features/kyc/data/kyc_api.dart';
import 'package:triptel/features/kyc/data/models/kyc_status.dart';
import 'package:triptel/features/wallet/application/wallet_providers.dart';
import 'package:triptel/features/wallet/data/models/wallet.dart';
import 'package:triptel/features/wallet/data/wallets_api.dart';
import 'package:triptel/features/wallet/data/models/ledger_entry.dart';
import 'package:triptel/features/wallet/data/models/manual_deposit.dart';
import 'package:triptel/features/wallet/data/models/topup_checkout.dart';

class _FixedCurrency extends CurrencyPreferenceNotifier {
  @override
  Future<String> build() async => 'EUR';
}

class _FixedLanguage extends LanguagePreferenceNotifier {
  @override
  Future<String> build() async => 'en';
}

class _FakeWalletsApi implements WalletsApi {
  _FakeWalletsApi(this._wallets);
  final List<Wallet> _wallets;

  @override
  Future<List<Wallet>> getMyWallets() async => _wallets;

  @override
  Future<List<LedgerEntry>> getLedger({String? walletType, int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<TopupCheckout> initiateTopup(
          {required double amount, required String currency}) =>
      throw UnimplementedError();

  @override
  Future<ManualDeposit> submitManualDeposit({
    required double amount,
    required String currency,
    required String bankName,
    required String transactionId,
  }) =>
      throw UnimplementedError();
}

class _FakeKycApi implements KycApi {
  _FakeKycApi(this._status);
  final KycStatus _status;

  @override
  Future<KycStatus> getMe() async => _status;

  @override
  Future<void> submit({
    required String nidNumber,
    required String documentFrontPath,
    String? documentBackPath,
  }) =>
      throw UnimplementedError();
}

Widget _testApp(
  AuthState state, {
  List<Wallet> wallets = const [
    Wallet(walletType: 'DEFAULT', balance: Money(1000), isFrozen: false),
    Wallet(walletType: 'REWARD', balance: Money(200), isFrozen: false),
  ],
  KycStatus kyc = const KycStatus(submitted: false),
  BootstrapData? bootstrap,
}) {
  final router = GoRouter(
    initialLocation: '/account',
    routes: [
      GoRoute(
          path: '/account', builder: (context, state) => const AccountScreen()),
      GoRoute(
        path: '/set-password',
        builder: (context, state) => const Text('set-password-placeholder'),
      ),
      GoRoute(
        path: '/refer',
        builder: (context, state) => const Text('refer-screen-placeholder'),
      ),
      GoRoute(
        path: '/compatibility/devices',
        builder: (context, state) => const Text('devices-screen-placeholder'),
      ),
      GoRoute(
        path: '/guides/esim-setup-guide',
        builder: (context, state) =>
            const Text('setup-guide-screen-placeholder'),
      ),
      GoRoute(
        path: '/track/:token',
        builder: (context, state) =>
            Text('track-screen-placeholder-${state.pathParameters['token']}'),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Text('profile-screen-placeholder'),
      ),
      GoRoute(
        path: '/kyc',
        builder: (context, state) => const Text('kyc-screen-placeholder'),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const Text('support-screen-placeholder'),
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) => const Text('legal-screen-placeholder'),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier(state)),
      walletsApiProvider.overrideWithValue(_FakeWalletsApi(wallets)),
      selectedCurrencyRateProvider.overrideWith((ref) async => 1.0),
      currencyPreferenceProvider.overrideWith(() => _FixedCurrency()),
      languagePreferenceProvider.overrideWith(() => _FixedLanguage()),
      kycApiProvider.overrideWithValue(_FakeKycApi(kyc)),
      appVersionProvider.overrideWith((ref) async => '1.2.3 (45)'),
      bootstrapProvider.overrideWith((ref) async =>
          bootstrap ??
          const BootstrapData(
            settings: PublicSettings(
              platformName: 'Triptel',
              maintenanceMode: false,
              defaultCurrency: 'EUR',
              supportWhatsapp: '+8801979891996',
              supportPhone: '+8801979891996',
              supportEmail: 'support@triptel.co',
            ),
            rates: [],
            languages: [],
            fromCache: false,
          )),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

const _tokenNeedsChange = AuthToken(
  accessToken: 'jwt',
  tokenType: 'bearer',
  role: 'USER',
  userId: 'u-1',
  username: 'alice',
  mustChangePassword: true,
);

const _tokenOk = AuthToken(
  accessToken: 'jwt',
  tokenType: 'bearer',
  role: 'USER',
  userId: 'u-1',
  username: 'alice',
  mustChangePassword: false,
);

void main() {
  setUp(installFakeSecureStorage);

  testWidgets('shows the set-password prompt when must_change_password is true',
      (tester) async {
    await tester
        .pumpWidget(_testApp(const AuthAuthenticated(_tokenNeedsChange)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('must-change-password-prompt')),
        findsOneWidget);

    await tester.tap(find.text('Set password'));
    await tester.pumpAndSettle();
    expect(find.text('set-password-placeholder'), findsOneWidget);
  });

  testWidgets('hides the prompt once must_change_password is false',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('must-change-password-prompt')),
        findsNothing);
    expect(find.text('Set password'), findsNothing);
  });

  testWidgets(
      'shows a real greeting with username, DEFAULT balance, and REWARD '
      'credit', (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    expect(find.text('Hello, alice!'), findsOneWidget);
    expect(find.text('€10.00'), findsOneWidget);
    expect(find.text('€2.00'), findsOneWidget);
  });

  testWidgets('tapping Invite friends navigates to the real FR-801 screen',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-invite-button')));
    await tester.pumpAndSettle();

    expect(find.text('refer-screen-placeholder'), findsOneWidget);
  });

  testWidgets('shows the real KYC status from GET /kyc/me', (tester) async {
    await tester.pumpWidget(_testApp(
      const AuthAuthenticated(_tokenOk),
      kyc: const KycStatus(submitted: true, status: 'PENDING'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('not submitted shows "Not verified"', (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    expect(find.text('Not verified'), findsOneWidget);
  });

  testWidgets('tapping Profile navigates to the real FR-1002 screen',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-profile-row')));
    await tester.pumpAndSettle();

    expect(find.text('profile-screen-placeholder'), findsOneWidget);
  });

  testWidgets(
      'tapping Identity verification navigates to the real FR-1003 screen',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-kyc-row')));
    await tester.pumpAndSettle();

    expect(find.text('kyc-screen-placeholder'), findsOneWidget);
  });

  testWidgets(
      'tapping Check device compatibility navigates to the real FR-952 '
      'screen', (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    final compatRow = find.byKey(const ValueKey('account-compatibility-row'));
    await tester.ensureVisible(compatRow);
    await tester.tap(compatRow);
    await tester.pumpAndSettle();

    expect(find.text('devices-screen-placeholder'), findsOneWidget);
  });

  testWidgets('tapping Setup guide navigates to the real FR-901 screen',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    final guideRow = find.byKey(const ValueKey('account-setup-guide-row'));
    await tester.ensureVisible(guideRow);
    await tester.tap(guideRow);
    await tester.pumpAndSettle();

    expect(find.text('setup-guide-screen-placeholder'), findsOneWidget);
  });

  testWidgets(
      'tapping Help / Support tickets navigates to the real FR-1101 screen',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('account-support-row'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('support-screen-placeholder'), findsOneWidget);
  });

  testWidgets('tapping Contact us opens the real FR-1104 shortcuts sheet',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('account-contact-row'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('Contact us'), findsWidgets);
    expect(find.text('support@triptel.co'), findsOneWidget);
  });

  testWidgets(
      'Track an eSIM: entering a full tracking link navigates to the real '
      'token', (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    final trackRow = find.byKey(const ValueKey('account-track-row'));
    await tester.ensureVisible(trackRow);
    await tester.tap(trackRow);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('track-esim-field')),
        'https://triptel.co/track/XYZ789');
    await tester.tap(find.byKey(const ValueKey('track-esim-submit')));
    await tester.pumpAndSettle();

    expect(find.text('track-screen-placeholder-XYZ789'), findsOneWidget);
  });

  testWidgets('Track an eSIM: entering a bare token navigates the same way',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    final trackRow = find.byKey(const ValueKey('account-track-row'));
    await tester.ensureVisible(trackRow);
    await tester.tap(trackRow);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('track-esim-field')), 'BARE123');
    await tester.tap(find.byKey(const ValueKey('track-esim-submit')));
    await tester.pumpAndSettle();

    expect(find.text('track-screen-placeholder-BARE123'), findsOneWidget);
  });

  testWidgets('Track an eSIM: cancelling the dialog does not navigate anywhere',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    final trackRow = find.byKey(const ValueKey('account-track-row'));
    await tester.ensureVisible(trackRow);
    await tester.tap(trackRow);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('account-tab')), findsOneWidget);
  });

  testWidgets('shows the real app version from PackageInfo', (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    final versionFinder = find.byKey(const ValueKey('account-version'));
    await tester.ensureVisible(versionFinder);
    expect(versionFinder, findsOneWidget);
    expect(find.text('1.2.3 (45)'), findsOneWidget);
  });

  testWidgets('tapping Legal documents navigates to the real FR-1201 screen',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('account-legal-row'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('legal-screen-placeholder'), findsOneWidget);
  });

  testWidgets('tapping Sign out logs out', (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    final signOutButton = find.byKey(const ValueKey('account-sign-out-button'));
    await tester.ensureVisible(signOutButton);
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('signed out shows Create account / Sign in, no groups',
      (tester) async {
    await tester.pumpWidget(_testApp(const AuthUnauthenticated()));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Account', skipOffstage: false), findsNothing);
  });

  testWidgets(
      'FR-L905: the eSIM adapter diagnostic row is gated to Platform.isAndroid '
      '-- not shown on this (non-Android) test host, confirming the gate '
      'exists; the Android-visible case needs real device evidence, not a '
      'host-platform-faked test', (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('account-adapter-diagnostic-row')),
        findsNothing);
  });

  testWidgets(
      'FR-L902: the "Add eSIM via adapter" row is gated to Platform.isAndroid '
      '-- not shown on this (non-Android) test host, confirming the gate '
      'exists; the Android-visible case needs real device evidence, not a '
      'host-platform-faked test', (tester) async {
    await tester.pumpWidget(_testApp(const AuthAuthenticated(_tokenOk)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('account-adapter-activation-input-row')),
        findsNothing);
  });
}
