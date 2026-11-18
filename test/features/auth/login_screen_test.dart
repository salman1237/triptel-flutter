import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:triptel/core/money/money.dart';
import 'package:triptel/core/network/api_exception.dart';
import 'package:triptel/features/auth/application/auth_providers.dart';
import 'package:triptel/features/auth/data/auth_api.dart';
import 'package:triptel/features/auth/data/models/auth_token.dart';
import 'package:triptel/features/auth/data/models/current_user.dart';
import 'package:triptel/features/auth/presentation/login_screen.dart';
import 'package:triptel/features/bootstrap/application/bootstrap_providers.dart';
import 'package:triptel/features/bootstrap/data/models/bootstrap_data.dart';
import 'package:triptel/features/bootstrap/data/models/public_settings.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/data/catalog_api.dart';
import 'package:triptel/features/catalog/data/models/country.dart';
import 'package:triptel/features/catalog/data/models/destination.dart';
import 'package:triptel/features/catalog/data/models/featured_package.dart';
import 'package:triptel/features/catalog/data/models/product.dart';
import 'package:triptel/features/checkout/presentation/checkout_review_screen.dart';
import 'secure_storage_test_mock.dart';

class _FakeCatalogApi implements CatalogApi {
  _FakeCatalogApi(this.product);
  final Product product;
  String? lastProductId;

  @override
  Future<List<Country>> getCountries(
          {String? search, bool popularOnly = false}) =>
      throw UnimplementedError();

  @override
  Future<List<String>> getCoverageCountries(String iso2) =>
      throw UnimplementedError();

  @override
  Future<Destination> getDestination(String slug) => throw UnimplementedError();

  @override
  Future<List<FeaturedPackage>> getFeaturedPackages() =>
      throw UnimplementedError();

  @override
  Future<Product> getProduct(String productId) async {
    lastProductId = productId;
    return product;
  }
}

final _noGoogleBootstrap = BootstrapData(
  settings: const PublicSettings(
    platformName: 'Triptel',
    maintenanceMode: false,
    defaultCurrency: 'EUR',
  ),
  rates: const [],
  languages: const [],
  fromCache: false,
);

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({this.error});
  final ApiException? error;

  @override
  Future<AuthToken> register({
    required String email,
    required String username,
    required String password,
    String? phone,
    String? fullName,
    String? referralCode,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthToken> login(
      {required String emailOrUsername, required String password}) async {
    if (error != null) throw error!;
    return AuthToken(
      accessToken: 'jwt-abc',
      tokenType: 'bearer',
      role: 'USER',
      userId: 'u-1',
      username: emailOrUsername,
      mustChangePassword: false,
    );
  }

  @override
  Future<AuthToken> loginWithGoogle({required String credential}) =>
      throw UnimplementedError();

  @override
  Future<void> forgotPassword({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> changePassword(
          {required String currentPassword, required String newPassword}) =>
      throw UnimplementedError();

  @override
  Future<CurrentUser> fetchCurrentUser() => throw UnimplementedError();

  @override
  Future<void> updatePhone(String phone) => throw UnimplementedError();
}

Widget _testApp({AuthApi? authApi, CatalogApi? catalogApi}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const Text('register-placeholder')),
      GoRoute(
          path: '/home',
          builder: (context, state) => const Text('home-placeholder')),
      GoRoute(
          path: '/forgot-password',
          builder: (context, state) =>
              const Text('forgot-password-placeholder')),
      GoRoute(
          path: '/suspended',
          builder: (context, state) => const Text('suspended-placeholder')),
      GoRoute(
          path: '/checkout/review',
          builder: (context, state) {
            final args = state.extra as CheckoutReviewArgs;
            return Text('checkout-review:${args.product.id}:'
                '${args.countryName}:${args.initialDiscountCode}');
          }),
    ],
  );

  return ProviderScope(
    overrides: [
      bootstrapProvider.overrideWith((ref) async => _noGoogleBootstrap),
      if (authApi != null) authApiProvider.overrideWithValue(authApi),
      if (catalogApi != null) catalogApiProvider.overrideWithValue(catalogApi),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeSecureStorage();
  });

  testWidgets('signs in with valid credentials and navigates to /home',
      (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('login-email-or-username')), 'salman2033');
    await tester.enterText(
        find.byKey(const ValueKey('login-password')), 'password');

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsOneWidget);
  });

  testWidgets('shows a client-side error when a field is empty',
      (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Enter your email/username and password'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);
  });

  testWidgets('shows the real 401 error and stays on the form', (tester) async {
    await tester.pumpWidget(
      _testApp(
        authApi: _FakeAuthApi(
          error: const ApiException(
              statusCode: 401, message: 'Invalid email/username or password'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('login-email-or-username')), 'salman2033');
    await tester.enterText(
        find.byKey(const ValueKey('login-password')), 'wrong');

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email/username or password'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);
  });

  testWidgets(
      'navigates to /suspended on a real 403 Account suspended (FR-109)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
          authApi: _FakeAuthApi(
              error: const ApiException(
                  statusCode: 403, message: 'Account suspended'))),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('login-email-or-username')), 'salman2033');
    await tester.enterText(
        find.byKey(const ValueKey('login-password')), 'password');

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('suspended-placeholder'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);
  });

  testWidgets(
      'FR-106: a pending purchase persisted before login resumes checkout '
      'instead of landing on Home', (tester) async {
    SharedPreferences.setMockInitialValues({
      'checkout.pendingPurchase': jsonEncode({
        'productId': 'prod-1',
        'countryName': 'Japan',
        'discountCode': 'WELCOME',
      }),
    });
    final catalogApi = _FakeCatalogApi(Product(
      id: 'prod-1',
      countryId: 1,
      titleEn: 'Japan 1GB 7Days',
      dataAmountGb: 1,
      validityDays: 7,
      retailPrice: const Money(500),
      isUnlimited: false,
      isActive: true,
      isFeatured: false,
    ));
    await tester
        .pumpWidget(_testApp(authApi: _FakeAuthApi(), catalogApi: catalogApi));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('login-email-or-username')), 'salman2033');
    await tester.enterText(
        find.byKey(const ValueKey('login-password')), 'password');

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(catalogApi.lastProductId, 'prod-1');
    expect(find.text('checkout-review:prod-1:Japan:WELCOME'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('checkout.pendingPurchase'), isNull);
  });

  testWidgets('navigates to /register via the secondary link', (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create an account instead'));
    await tester.pumpAndSettle();

    expect(find.text('register-placeholder'), findsOneWidget);
  });

  testWidgets('navigates to /forgot-password via the Forgot password? link',
      (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('login-forgot-password')));
    await tester.pumpAndSettle();

    expect(find.text('forgot-password-placeholder'), findsOneWidget);
  });
}
