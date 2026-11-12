# claude-progress.md
Session log. Read first at session start, update last at session end.

## Current state (2026-11-12) — mode: AUTONOMOUS (no approvals; commit + push every step)
- **Repo:** https://github.com/salman1237/triptel-flutter (public, `main`).
- **Phase:** Auth in progress (FR-101, FR-102 done; FR-103 next — likely `blocked`).
- **Active feature:** none.
- **Next step:** run the `next-feature` loop: mark **FR-103** (Google Sign-In)
  `active`. This needs an Android OAuth client for `co.triptel.app` + the
  debug keystore's SHA-1, which only the user can register in Google Cloud
  Console (see "User actions pending" — still outstanding). Expect to set
  FR-103 `state: "blocked"` with that reason after confirming nothing else is
  buildable first (e.g. the `google_sign_in` package wiring itself, gated
  behind the missing client id), then move straight to **FR-104** (forgot/reset
  password — request link in-app, the emailed link opens the web since there's
  no app deep link for password reset) and **FR-105** (forced password change:
  route to Set Password when `must_change_password` is true or on the 403
  "set your own password" response — `AuthNotifier` already has
  `must_change_password` available from FR-102's login). After auth:
  compatibility (FR-950..952), then catalog (FR-201+), then checkout (FR-301+).
  Low-priority follow-ups logged, not urgent: **FR-005b**, **FR-006b**.

## Done
- 2026-11-12 — Session 8 (FR-102):
  - `lib/features/auth/presentation/login_screen.dart` — email-or-username +
    password; only checks both fields are non-empty client-side (reusing
    FR-101's `validateEmail` would wrongly reject a bare username). Calls the
    `AuthNotifier.login()` method FR-101's session already built, surfaces
    real backend errors (401 invalid credentials, 403 suspended — shown
    inline for now; FR-109's dedicated suspended screen isn't built yet, a
    deliberate, logged scope boundary) inline.
  - `AccountScreen`'s unauthenticated state now shows both "Create account"
    and "Sign in".
  - Tests: `must_change_password` persistence proven end-to-end (API response
    → `AuthNotifier.login()` → `SecureStore.saveToken` → read back), proven
    non-vacuous. `bash harness.sh verify` green (99 tests). On-device: real
    login against live beta using a **different, pre-existing** real account
    (username `salman2033`, provided verbally by the user and never written
    to any repo file) — confirmed "Signed in as salman2033" afterward, a
    genuinely independent proof from FR-101's fresh-registration evidence.
  - Found and fixed a test-infrastructure-only bug while writing tests: the
    screen's "Sign in" heading and its submit button's "Sign in" label made
    `find.text('Sign in')` ambiguous; added a `ValueKey` to the button and
    switched affected taps to `find.byKey`. Confirmed this didn't change what
    a real user sees (both strings still legitimately say "Sign in" on screen).
  - Reviewer agent: PASS.
  - Commits: `24ca106` (feature code), `f641aec` (state → passing).
- 2026-11-12 — Session 7 (FR-101):
  - `lib/core/storage/secure_store.dart` — JWT + `must_change_password` only
    (Rules.md), via `flutter_secure_storage` (no official test API, so
    `test/features/auth/secure_storage_test_mock.dart` fakes its method
    channel — channel name and method names confirmed against the pinned
    `flutter_secure_storage_platform_interface` version's source directly).
  - `apiClientProvider` (bootstrap_providers.dart) now wires its
    `tokenProvider` to `SecureStore.readToken` — `ApiClient` is the only thing
    that ever attaches `Authorization`, per Architecture.md.
  - `lib/features/auth/` — `AuthApi.register()/login()`, pure
    `validateRegisterPassword`/`validateEmail`/`validateUsername`,
    `AuthNotifier` (register/login/logout, one cohesive class since they
    share session state — only `register()`'s behavior is tested/claimed
    here; FR-102/107/108 will add their own tests against the same already-built
    methods). `RegisterScreen` validates client-side before calling the API,
    shows real backend errors inline, pre-fills a pending referral code from
    FR-007 without fighting a value the user already typed.
  - `AccountScreen` (FR-004's placeholder) now shows "Create account" or
    "Signed in as `<username>`" + "Sign out" depending on session state.
  - Tests: 19, two non-vacuousness proofs (password validation, referral
    pre-fill — the second added after the reviewer flagged it as an untested
    spec behavior). `bash harness.sh verify` green (97 tests, confirming the
    `apiClientProvider`/`account_screen.dart` changes didn't regress FR-001..007).
  - On-device: real end-to-end registration against live beta — created an
    actual new account (`triptel_test_<timestamp>`), confirmed the signed-in
    state afterward (`artifacts/FR-101-signed-in.png`). Gotcha hit during this
    run: the Vivo device's secure keyboard blocks `adb screencap` while a
    password field has focus — screenshots come back as 0-byte files; tap
    elsewhere to drop focus first, and never use `adb shell input keyevent 4`
    (BACK) to dismiss a keyboard on a route with no back-stack, since it exits
    the app instead.
  - Reviewer agent: PASS, flagged the untested referral pre-fill — fixed
    before this commit rather than deferred.
  - Commits: `95cf287` (feature code), `efaad36` (state → passing).
- 2026-11-12 — Session 6 (FR-007 — Foundation section complete):
  - `lib/core/deeplink/` — `parseDeepLink`/`extractReferralCode` (pure),
    `handleDeepLink` dispatch, `app_links`-backed listener mirroring FR-002's
    fetch+cache shape. Referral codes persist to `shared_preferences` for
    FR-803/FR-101; payment-callback params and tracking tokens sit in state
    providers until checkout (FR-306/307) and tracking (FR-501) exist to
    consume them.
  - New top-level `/track/:token` route + `TrackingScreen` placeholder;
    `DeepLinkBridge` activates the listener and navigates there.
  - **Found and fixed a real infra gap**: `AndroidManifest.xml` had no `https`
    intent-filter at all — only `triptel://` — so `/track/` links could never
    reach the app on a real device no matter how correct the Dart parsing was.
    Added one scoped to `pathPrefix=/track`, no `autoVerify` (no backend
    `.well-known/assetlinks.json` yet — logged in DECISIONS.md and already
    tracked as "Blocked on backend" #7).
  - Tests: 19, proven non-vacuous. `bash harness.sh verify` green (69 tests).
    On-device: rebuilt, reinstalled, sent real `adb shell am start -a
    android.intent.action.VIEW -d <uri>` intents for both schemes to the
    running app — both delivered; `artifacts/FR-007-tracking.png` shows the
    real `TrackingScreen` with the token from a live deep link, not a widget
    test.
  - Reviewer agent: PASS; trimmed an undocumented `www.triptel.co` host (API.md
    only lists `triptel.co`/`beta.triptel.co`) per its note before committing.
  - User asked about integrating the `shurjopay` pub.dev package (a
    server-side SDK) — confirmed with them this app doesn't need it: per
    API.md §9 the client only opens the backend's `checkout_url` in a WebView
    and intercepts `triptel://`, which FR-007 already wired up and FR-307
    will consume. No new dependency added.
  - Commits: `e882e0e` (feature code), `19fd12a` (state → passing).
- 2026-11-12 — Session 5 (FR-006):
  - `lib/core/i18n/` — `translations_api.dart`/`translations_cache.dart`/
    `translations_loader.dart` mirror FR-002's bootstrap fetch+cache+fallback
    shape exactly, for `/settings/translations/{code}`. `language_preference.dart`
    has three pure rules: `resolveInitialLanguage` (stored-if-active → en-if-active
    → first-active), `isRtlLanguage` (false for unknown codes, never guesses),
    `translate` (namespace/key lookup with fallback — an additive client-side
    safety net, not competing with the server's own English back-fill).
  - `language_providers.dart` persists to `shared_preferences` key
    `language.selected` (not secure storage). `rtl_scope.dart`'s `RtlScope`
    wraps the app's real content in the right `Directionality`; wired into
    `main.dart` inside `BootstrapGate` so splash/maintenance/error stay LTR —
    a known, disclosed limitation (FR-006b), not silently shipped.
  - `language_pill_switcher.dart` mirrors FR-005's currency pill; lives on
    Account's FR-004 placeholder.
  - Tests: 17, proven non-vacuous (broke `resolveInitialLanguage`'s fallback,
    watched it fail for real, restored). `bash harness.sh verify` green (50
    tests total). On-device, full real flow against live beta: EN pill on
    Account → tapped → sheet showed real `/settings/languages` (English,
    বাংলা, العربية, Español, Français, Deutsch) → tapped Arabic → entire app
    mirrored to RTL (pill moved to top-left, bottom tab order reversed,
    chevron/text flipped) — `artifacts/FR-006-account2.png`, `-sheet.png`,
    `-rtl.png`.
  - Also corrected FR-006's stale `verification` field in `feature_list.json`
    (was copy-pasted from FR-002/003 before this code existed) to point at
    `test/core/i18n`; logged in `DECISIONS.md`.
  - Reviewer agent: PASS, with the FR-006b advisory above.
  - Commits: `4b2e47e` (feature code), `41e80a8` (state → passing + FR-006b logged).
- 2026-11-12 — Session 4 (FR-005):
  - `lib/core/money/money.dart` — `Money` (EUR integer cents, parsed from API
    decimal strings; +/-/comparisons never touch `double`, only the one-off
    display multiply in `formatMoney` does, which Rules.md's "never accumulate
    doubles" allows since it's display-only and not fed back into further math).
  - `currency_format.dart` (symbol map + JPY zero-decimal rule, API.md §0.2),
    `currency_preference.dart` (pure `resolveInitialCurrency` + `resolveRate`,
    manual-override-wins per API.md §1), `currency_providers.dart` (Riverpod:
    `CurrencyPreferenceNotifier` persists to `shared_preferences`, not secure
    storage — this is a non-sensitive display setting), `currency_pill_switcher.dart`
    (header pill + bottom-sheet picker, Design_System.md §3).
  - Refactored `sharedPreferencesProvider` out of `bootstrap_providers.dart` into
    `core/storage/shared_prefs_provider.dart` so both features share one instance
    — re-verified FR-002/003/004's tests still pass after the move.
  - `home_screen.dart` (FR-004's placeholder) now hosts the pill, since
    Design_System.md says the pill switcher belongs in headers — minimal,
    additive touch, not FR-201 scope creep.
  - Signed-in sync via `PUT /auth/me/preferences` deliberately deferred — no
    auth exists yet (FR-101..109 `not_started`); local persistence only for now.
  - Tests: 20 tests, proven non-vacuous (forced JPY to 2 decimals, watched the
    format test fail for real, restored). `bash harness.sh verify` green (33
    tests total). On-device, a full real flow against live beta: EUR pill on
    Home → tapped → sheet showed real `/settings/rates` currencies → tapped
    BDT → pill updated to "BDT ৳" (`artifacts/FR-005-home.png`,
    `-sheet.png`, `-sheet2.png`, `-selected.png`).
  - Reviewer agent: PASS, with one advisory — `selectedCurrencyRateProvider`'s
    own Riverpod glue (two `ref.watch` calls) has no direct test, only the pure
    `resolveRate` function it calls does; no live exposure today since nothing
    consumes that provider yet. Logged as **FR-005b** rather than fixed inline
    (Rules.md: don't "also fix" nearby things).
  - Commits: `b427c21` (feature code), `55d09db` (state → passing + FR-005b logged).
- 2026-11-12 — Session 3 (FR-004):
  - `lib/app/router.dart` — `GoRouter` with one `StatefulShellRoute.indexedStack`,
    4 branches (`/home`, `/my-esims`, `/wallet`, `/account`), each its own
    navigation stack.
  - `lib/app/app_shell.dart` — hand-rolled bottom nav bar from FR-001 tokens
    (not Material's `BottomNavigationBar`), `goBranch(i, initialLocation: i ==
    currentIndex)` so tapping the active tab resets it to root but switching
    tabs preserves each one's stack.
  - Four placeholder screens (`lib/features/{catalog,esims,wallet,account}/presentation/`),
    each just an `EmptyState` pointing at the FR that owns the real content
    (FR-201/402/601/1001) — FR-004 is shell-only by design.
  - `lib/main.dart` switched to `MaterialApp.router`; `BootstrapGate` now wraps
    the whole routed app via the `builder` param so maintenance mode still
    gates everything, including go_router's own error page.
  - Test: `test/app/shell_test.dart` renders the full app (bootstrapProvider
    overridden to skip the network), asserts all 4 tabs and that tapping each
    navigates to the right screen. Proven non-vacuous: pointed `/wallet` at
    `AccountScreen`, got a real "Found 0 widgets with type WalletScreen"
    failure, restored, green again.
  - `bash harness.sh verify` green (13 tests). On-device (10EF1302BJ000R5):
    `artifacts/FR-004-home.png` after a real bootstrap round-trip, then a real
    `adb shell input tap` on the Wallet tab produced `artifacts/FR-004-wallet.png`
    with Wallet now highlighted — confirms live tab-switching, not just the
    widget test.
  - Reviewer agent: PASS (re-ran the revert experiment independently, confirmed
    FR-001's tests still pass, checked Rules.md scope — no raw colours, no
    early-built Home/Wallet/etc. content).
  - Commits: `ea15221` (feature code), `e022ad3` (state → passing).
- 2026-11-12 — Session 2 (FR-002, FR-003):
  - `lib/core/config/env.dart` (API_BASE_URL dart-define), `lib/core/network/`
    (`ApiClient` — the one dio instance, `ApiException` mapping `detail` per
    API.md §0.1).
  - `lib/features/bootstrap/` — models matching the live beta `/settings/public`,
    `/settings/rates`, `/settings/languages` shapes; `BootstrapCache` (plain
    `shared_preferences`, not secure storage — only non-sensitive settings);
    `loadBootstrap()` (plain-Dart business rule: fetch fresh → cache → on any
    failure fall back to last cache, else rethrow) — Architecture.md's
    "business rules in plain Dart" followed here deliberately so it's unit-testable
    without a widget tree.
  - `BootstrapGate` wires splash/error/maintenance/content branching into
    `main.dart`'s `home`; `MaintenanceScreen` (FR-003) hides null support
    contacts, Retry calls `ref.invalidate(bootstrapProvider)`.
  - Tests: `bootstrap_loader_test.dart` (fresh-fetch-and-cache, cache-fallback,
    rethrow-when-no-cache — proven non-vacuous by disabling `cache.save()` and
    watching 2 tests fail for real reasons, then restoring), `bootstrap_gate_test.dart`
    (loading/maintenance-true/maintenance-false branches via provider override).
    `test/widget_test.dart` updated to override `bootstrapProvider` so the smoke
    test doesn't hang on a real network call.
  - `bash harness.sh verify` green. On-device (10EF1302BJ000R5), a **real** network
    round-trip against `beta.triptel.co`: `artifacts/FR-002.png` (splash mid-load),
    `artifacts/FR-002-loaded.png` (live `maintenance_mode=false` response passed
    through to content 5 s later). FR-003 has no on-device screenshot — the live
    beta isn't in maintenance mode, so only the widget-test evidence exists
    (disclosed limitation, not a workaround).
  - Reviewer agent: PASS for both (spot-checked models vs API.md, re-ran the
    cache-save-disable experiment independently, re-ran `harness.sh verify`,
    checked Rules.md/Architecture.md compliance).
  - Commits: `f07ad28` (feature code), `63e6d47` (state → passing).
- 2026-11-12 — Session 1 (FR-001):
  - Theme tokens (`lib/core/theme/tokens.dart`, `typography.dart`, `theme.dart`) exactly
    matching Design_System.md §1 (colours, radii, Plus Jakarta Sans type scale).
  - Full §4 shared-component library in `lib/core/widgets/`: TriptelScaffold, HeroHeader,
    PillButton, SegmentedPill, SearchPill, FlagAvatar, CountryRow, PlanWheelPicker,
    PlanOptionTile, PriceText, StatusChip, BalanceCard, ListGroup/ListRow, InfoBox,
    StickyTotalBar, PaymentMethodSheet, EsimQr (EC H, 22% logo, white disc per Rules.md),
    UsageRing, EmptyState, ErrorState.
  - `lib/app/theme_preview_screen.dart` renders all of them; wired as `main.dart`'s
    temporary `home` until FR-002/FR-004 add the real bootstrap + shell.
  - Tests: `test/core/theme/tokens_test.dart` (token/typography values) and
    `shared_components_test.dart` (every component renders + a tap interaction).
    Proven non-vacuous: broke `AppColors.primary`, watched both test files fail,
    restored, watched them pass again.
    `bash harness.sh verify` green (analyze, format, full suite, debug APK build).
  - Device screenshot `artifacts/FR-001.png` on 10EF1302BJ000R5 (Triptel purple/white,
    matches Design_System §2 Home/Account/Country-plans patterns combined in one
    kitchen-sink preview).
  - Reviewer agent: PASS (spot-checked tokens, raw-colour grep, vacuousness test,
    re-ran `harness.sh verify` and the screenshot independently).
  - Commits: `a4f79a5` (feature code), `359269e` (state → passing).
  - Gotcha: `dart format --output=none --set-exit-if-changed` only *reports* diffs,
    it never writes; `dart format lib test` (no `--output=none`) is what actually
    fixes formatting before `harness.sh verify` will pass clean.
- 2026-11-12 — Session 0 (Initialize):
  - `flutter create` (Android + iOS), app id `co.triptel.app`, Gradle 8.11.1 /
    AGP 8.7.3 / Kotlin 2.1 for JDK 23, minSdk 23, `triptel://` deep-link scheme
    on both platforms. Dependencies added (see pubspec.yaml).
  - Native eSIM-detection channel `co.triptel.app/esim` stubbed: Android
    `MainActivity.kt` (EuiccManager + FEATURE_TELEPHONY_EUICC + Build info),
    iOS `AppDelegate.swift` (CTCellularPlanProvisioning + machine id). Not
    yet called from Dart, not yet verified → FR-950.
  - Harness written: CLAUDE.md, AGENTS.md, docs/*, feature_list.json (70 FRs),
    DECISIONS.md, init.sh, Makefile, .claude/ (settings, hooks, skills, reviewer
    agent), .mcp.json (context7, mobile-mcp, dart).
  - docs/API.md verified against beta's live OpenAPI + backend code.
  - Eskimo app walked on the vivo V2344; 15 reference screenshots in
    `docs/design-reference/`.
  - `harness.sh` is the canonical runner (no `make` on this machine); hooks
    pipe-tested (destructive/prod-API commands → exit 2; unverified "passing" → exit 2).
  - User direction: autonomous loop, no approvals, commit and push everything.
  - Redacted the device owner's name/referral code in two reference screenshots
    before publishing the repo publicly.

## Blocked on backend (do not fake these)
1. **Product currency label:** eSIM Access products say `"USD"` but are charged
   as EUR 1:1 (`catalog_parsing.py:235`). App treats all as EUR. Owner to decide
   whether to convert USD→EUR at sync.
2. **Gateway return for wallet top-up and eSIM top-up** redirects to the web, not
   `triptel://` (only order payments have the `ORDERPAY-M-` variant). App
   intercepts in the WebView; a `mobile` flag on those endpoints would be cleaner.
3. `GET /auth/me` doesn't return `must_change_password`.
4. `GET /orders/my-esims` returns original plan totals (stale after top-up) and
   no `share_token`.
5. No endpoint to list my manual deposits; no receipt upload.
6. No push-notification registration; no account-deletion endpoint (store requirement).
7. No universal-link `.well-known` files for `triptel.co` (track/ref links open web).
8. `coverage_networks` holds IP-export region for eSIM Access, not carriers.

## User actions pending
- Register an Android OAuth client (`co.triptel.app` + debug SHA-1) for Google Sign-In.
- Optional: `flutter upgrade` (≥ 3.35) to enable the Dart MCP server.
