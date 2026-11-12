# claude-progress.md
Session log. Read first at session start, update last at session end.

## Current state (2026-11-12) — mode: AUTONOMOUS (no approvals; commit + push every step)
- **Repo:** https://github.com/salman1237/triptel-flutter (public, `main`).
- **Phase:** Initialize (harness only, no feature code yet).
- **Active feature:** none.
- **Next step:** run the `next-feature` loop: mark **FR-001** (theme + shared components) `active` and build it
  from `docs/Design_System.md` + `docs/design-reference/`. Then FR-002 → FR-004,
  then auth, then the compatibility features (FR-950..952).

## Done
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
