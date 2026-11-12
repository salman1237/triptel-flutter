# DECISIONS.md
Judgment calls, newest first. Each: what, why, revisit-if.

## 2026-11-12 — FR-006's verification path corrected to where its tests live
`feature_list.json`'s FR-006 `verification` was a stale placeholder
(`flutter test test/features/bootstrap`, copy-pasted from FR-002/003 before
FR-006 had any code). Changed to `flutter test test/core/i18n`, matching
FR-005's precedent of putting cross-cutting, non-feature-specific logic
(currency, language) under `core/` rather than `features/`. **Why:** the
verification command must exercise the code that was actually written;
pointing it at `test/features/bootstrap` would have "passed" without running
any of FR-006's own tests. **Revisit if:** language/i18n logic grows enough
to warrant its own `features/i18n/` folder instead of living in `core/`.

## 2026-11-12 — Folder and repo layout
`D:\eSim\Triptel-flutter`, its own git repo, ignored by the parent `D:\eSim`
repo (same arrangement as `Triptel-MobileApp`). **Why:** user asked for a separate
folder; keeps Flutter out of the Dokploy-deployed monorepo.

## 2026-11-12 — App identity shared with the RN app
`co.triptel.app`, scheme `triptel://`. **Why:** the backend already redirects
mobile order payments to `triptel://payment-callback`, and the Google Android
OAuth client is tied to the package name. **Revisit if:** the RN app and this app
must coexist on one phone (then one needs a different id + its own OAuth client).

## 2026-11-12 — UX reference: Eskimo eSIM, re-skinned
Follow Eskimo's layout and flows (screenshots in `docs/design-reference/`), in
Triptel colours from the logo (`#5E3CDA`, `#452C9B`, `#3AA0F0`). **Why:** user's
explicit direction ("not copy but follow the style… purple white theme").
Deviation: 4 bottom tabs (adds My eSIMs) instead of Eskimo's 3.

## 2026-11-12 — Treat every amount as EUR
Products from eSIM Access carry `currency: "USD"` but checkout charges them 1:1 from
EUR wallets. The app follows actual charging behaviour (EUR), like the web.
**Revisit if:** the backend converts eSIM Access prices to EUR at sync.

## 2026-11-12 — Gateway hand-off via in-app WebView with URL interception
One mechanism for all three ShurjoPay flows: intercept `triptel://` (orders) and
the web return URLs (wallet top-up, eSIM top-up), then re-read server state.
**Why:** zero backend change needed for top-ups today. **Revisit if:** the backend
adds `mobile` return variants for top-ups — then prefer the custom scheme everywhere.

## 2026-11-12 — Handset compatibility is detected natively
Platform channel instead of a package: Android `FEATURE_TELEPHONY_EUICC` +
`EuiccManager.isEnabled()`, iOS `CTCellularPlanProvisioning`. Verdict logic in
Dart. Three outcomes (supported / not / unknown). Never blocks purchase (Eskimo
does the same: "Buy now, use later"). **Why:** no backend API exists; packages for
this are thin wrappers around the same calls.

## 2026-11-12 — Stack: Riverpod + go_router + dio
Mainstream, testable without a widget tree, works on the installed Flutter 3.27.

## 2026-11-12 — Flutter stays at 3.27.1 for now
Installed and working with the phone. The Dart MCP server needs ≥ 3.35; upgrading
the global SDK is the user's call (affects other projects on this machine).

## 2026-11-12 — Gradle 8.11.1 / AGP 8.7.3 / Kotlin 2.1.0
Template's Gradle 8.3 can't run on the installed JDK 23.
