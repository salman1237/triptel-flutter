# claude-progress.md
Session log. Read first at session start, update last at session end.

## Current state (2026-11-12) — mode: AUTONOMOUS (no approvals; commit + push every step)
- **Repo:** https://github.com/salman1237/triptel-flutter (public, `main`).
- **Phase:** Foundation (FR-001 done; FR-002 next).
- **Active feature:** none.
- **Next step:** run the `next-feature` loop: mark **FR-002** (bootstrap:
  `/settings/public`, `/rates`, `/languages` with cache + splash) `active` and build it
  from `docs/API.md` §bootstrap endpoints + `docs/Functional_Requirements.md` FR-002/003.
  Then FR-003 (maintenance gate) → FR-004 (4-tab shell) → FR-005..007, then auth,
  then the compatibility features (FR-950..952).

## Done
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
