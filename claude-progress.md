# claude-progress.md
Session log. Read first at session start, update last at session end.

## Current state (2026-11-12) — mode: AUTONOMOUS (no approvals; commit + push every step)
- **Repo:** https://github.com/salman1237/triptel-flutter (public, `main`).
- **Phase:** Foundation (FR-001..005 done; FR-006 next).
- **Active feature:** none.
- **Next step:** run the `next-feature` loop: mark **FR-006** (language switcher &
  RTL: `/settings/languages` list already cached by bootstrap, load
  `/settings/translations/{code}` on switch, `EdgeInsetsDirectional`/
  `AlignmentDirectional` only per Rules.md so Arabic renders RTL) `active`. Then
  FR-007 (deep links) closes out the Foundation section, then auth (FR-101..109),
  then compatibility (FR-950..952). **FR-005b** (not_started, low priority) is a
  reviewer-flagged follow-up: add a direct provider-level test for
  `selectedCurrencyRateProvider` once a real screen consumes it — currently
  nothing does, so it's not urgent.

## Done
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
