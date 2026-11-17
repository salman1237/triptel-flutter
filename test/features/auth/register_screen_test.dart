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
import 'package:triptel/features/auth/presentation/register_screen.dart';
import 'package:triptel/features/catalog/application/catalog_providers.dart';
import 'package:triptel/features/catalog/data/catalog_api.dart';
import 'package:triptel/features/catalog/data/models/country.dart';
import 'package:triptel/features/catalog/data/models/destination.dart';
import 'package:triptel/features/catalog/data/models/product.dart';
import 'package:triptel/features/checkout/presentation/checkout_review_screen.dart';
import 'package:triptel/features/referrals/application/referrals_providers.dart';
import 'package:triptel/features/referrals/data/models/referral_summary.dart';
import 'package:triptel/features/referrals/data/referrals_api.dart';
import 'secure_storage_test_mock.dart';

class _FakeCatalogApi implements CatalogApi {
  _FakeCatalogApi(this.product);
  final Product product;

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
  Future<Product> getProduct(String productId) async => product;
}

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
  }) async {
    if (error != null) throw error!;
    return const AuthToken(
      accessToken: 'jwt-abc',
      tokenType: 'bearer',
      role: 'USER',
      userId: 'u-1',
      username: 'alice',
      mustChangePassword: false,
    );
  }

  @override
  Future<AuthToken> login(
          {required String emailOrUsername, required String password}) =>
      throw UnimplementedError();

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

class _FakeReferralsApi implements ReferralsApi {
  _FakeReferralsApi({this.validResult});
  final ReferralValidation? validResult;

  @override
  Future<ReferralValidation> validate(String code) async =>
      validResult ?? const ReferralValidation(valid: false);

  @override
  Future<ReferralSummary> getMe() => throw UnimplementedError();

  @override
  Future<ReferralSummary> claim(String code) => throw UnimplementedError();
}

Widget _testApp(
    {AuthApi? authApi, CatalogApi? catalogApi, ReferralsApi? referralsApi}) {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/home',
          builder: (context, state) => const Text('home-placeholder')),
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
      if (authApi != null) authApiProvider.overrideWithValue(authApi),
      if (catalogApi != null) catalogApiProvider.overrideWithValue(catalogApi),
      referralsApiProvider
          .overrideWithValue(referralsApi ?? _FakeReferralsApi()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeSecureStorage();
  });

  testWidgets('submits with valid fields and navigates to /home on success',
      (tester) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('register-email')), 'a@b.co');
    await tester.enterText(
        find.byKey(const ValueKey('register-username')), 'alice');
    await tester.enterText(
        find.byKey(const ValueKey('register-password')), 'min8chars');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsOneWidget);
  });

  testWidgets(
      'shows a client-side error for a short password without calling the API',
      (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('register-email')), 'a@b.co');
    await tester.enterText(
        find.byKey(const ValueKey('register-username')), 'alice');
    await tester.enterText(
        find.byKey(const ValueKey('register-password')), 'short');

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);
  });

  testWidgets(
      'shows the backend error (e.g. duplicate email) and stays on the form', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        authApi: _FakeAuthApi(
          error: const ApiException(
              statusCode: 400, message: 'Email or username already exists'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('register-email')), 'a@b.co');
    await tester.enterText(
        find.byKey(const ValueKey('register-username')), 'alice');
    await tester.enterText(
        find.byKey(const ValueKey('register-password')), 'min8chars');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Email or username already exists'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);
  });

  testWidgets('pre-fills the referral code left by a ref link (FR-007)',
      (tester) async {
    SharedPreferences.setMockInitialValues({'referral.pendingCode': 'ABC123'});

    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    expect(find.text('ABC123'), findsOneWidget);
  });

  testWidgets(
      'FR-106: a pending purchase persisted before register resumes '
      'checkout instead of landing on Home', (tester) async {
    SharedPreferences.setMockInitialValues({
      'checkout.pendingPurchase': jsonEncode({
        'productId': 'prod-2',
        'countryName': 'Bangladesh',
      }),
    });
    final catalogApi = _FakeCatalogApi(Product(
      id: 'prod-2',
      countryId: 1,
      titleEn: 'Bangladesh 1GB 7Days',
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
        find.byKey(const ValueKey('register-email')), 'a@b.co');
    await tester.enterText(
        find.byKey(const ValueKey('register-username')), 'alice');
    await tester.enterText(
        find.byKey(const ValueKey('register-password')), 'min8chars');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('checkout-review:prod-2:Bangladesh:null'), findsOneWidget);
    expect(find.text('home-placeholder'), findsNothing);
  });

  testWidgets('does not overwrite a referral code the user already typed',
      (tester) async {
    SharedPreferences.setMockInitialValues({'referral.pendingCode': 'ABC123'});

    await tester.pumpWidget(_testApp(authApi: _FakeAuthApi()));
    await tester.enterText(
        find.byKey(const ValueKey('register-referral')), 'TYPED');
    await tester.pumpAndSettle();

    expect(find.text('TYPED'), findsOneWidget);
    expect(find.text('ABC123'), findsNothing);
  });

  testWidgets(
      'FR-803: a valid code shows the real referrer username and reward',
      (tester) async {
    await tester.pumpWidget(_testApp(
      referralsApi: _FakeReferralsApi(
        validResult: const ReferralValidation(
            valid: true, referrerUsername: 'bob', joiningReward: Money(100)),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('register-referral')), 'BOB123');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Invited by @bob, you get €1.00'), findsOneWidget);
  });

  testWidgets('FR-803: an invalid code shows a real invalid message',
      (tester) async {
    await tester.pumpWidget(_testApp(
      referralsApi: _FakeReferralsApi(
          validResult: const ReferralValidation(valid: false)),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('register-referral')), 'NOPE');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('This referral code is not valid.'), findsOneWidget);
  });

  testWidgets('FR-803: clearing the code removes the validation message',
      (tester) async {
    await tester.pumpWidget(_testApp(
      referralsApi: _FakeReferralsApi(
          validResult: const ReferralValidation(valid: false)),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('register-referral')), 'NOPE');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('This referral code is not valid.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('register-referral')), '');
    await tester.pump();

    expect(find.text('This referral code is not valid.'), findsNothing);
  });
}
