# claude-progress.md
Session log. Read first at session start, update last at session end.

## Current state (2026-11-13) — mode: AUTONOMOUS (no approvals; commit + push every step)
- **Repo:** https://github.com/salman1237/triptel-flutter (public, `main`).
- **CI:** `.github/workflows/release-apk.yml` builds `flutter build apk --release`
  (beta API) on every push to `main` and publishes it to the repo's "latest"
  GitHub Release (https://github.com/salman1237/triptel-flutter/releases/tag/latest,
  asset `triptel-latest.apk`, ~50MB). The APK itself is never committed to git --
  the debug build is ~250MB, over GitHub's 100MB hard file-size limit, and a
  growing binary in every commit would bloat this public repo's clone size
  forever. Requires JDK 17 pinned via `actions/setup-java` (ubuntu-latest's
  default JDK is too new for Gradle 8.11.1's build scripts).
- **Phase:** Auth section (B) complete (FR-101..105, FR-107, FR-108, FR-109
  done; FR-106 blocked). Compatibility (K) section complete: FR-950, FR-951,
  FR-952, FR-953 all passing (FR-953b — checkout gate/install gating —
  deferred, not_started, needs FR-301+/FR-404/FR-310 to exist first).
  Catalog (C): FR-201 through FR-206 all passing (FR-201b — usage summary
  for signed-in users with an active eSIM — and FR-202b — featured
  "Global" package card — both `blocked`, not just deferred; see reasons
  in `feature_list.json`). FR-005b, FR-006b (money/i18n follow-ups) also
  passing; FR-105b blocked (no real gated endpoint exists yet). Checkout
  (D): FR-301 through FR-306 all passing — first real, user-approved
  wallet purchase completed live (Order ORD-20261114-4DB40D, a real
  eSIM provisioned). New `lib/features/wallet/` data layer (Wallet
  model, WalletsApi) started ahead of FR-601, same incremental pattern
  as FR-007. **FR-307** (ShurjoPay checkout) also now passing — real
  WebView against the beta ShurjoPay sandbox gateway, backed out
  cleanly without completing any payment. **FR-308** (provisioning
  progress step list) also now passing — a second small real purchase
  (Order ORD-20261114-6D7389) proved the new `OrderStatusScreen` wiring
  end-to-end; the actual step-list screen itself was screenshotted via
  a temporary, never-committed local rig (see DECISIONS.md) since the
  real purchase completed too fast to catch it mid-poll. **FR-309**
  (still-preparing message) also now passing — a pure text change,
  evidenced via the same temporary-rig technique (no real purchase or
  real ~170s wait needed this time either). **FR-401** (EsimQr
  component) also now passing — pulled forward out of array order
  since FR-310 depends on it (same precedent as the wallet layer ahead
  of FR-601); the component already existed from earlier scaffolding
  and needed only tests, no source changes. **FR-310** (purchase
  success screen) also now passing — QR (reusing FR-401's EsimQr),
  a 1-tap install button double-gated on a valid LPA: string and
  FR-950's compatibility verdict, copy activation code, "Go to My
  eSIMs". On-device evidence used synthetic order data (via the same
  temp-rig technique) instead of a third real purchase, since this
  screen's rendering only depends on the Order object's contents, not
  how it was obtained — and a real purchase would only risk a real
  ICCID/LPA/QR secret in a screenshot for no extra test signal.
  **FR-311** (purchase failure) also now passing — this behavior
  already existed as a side effect of FR-306's original work; this
  feature just locked it in with 5 dedicated tests (explicit FAILED
  only, never CANCELLED; refund message) and a clarifying doc comment,
  no logic change. **FR-402** (My eSIMs list) also now passing —
  real `GET /orders/my-esims` cards with status chip, data/validity,
  "Bought for me/by me", pull to refresh, empty state → explore. Real
  on-device evidence used the signed-in account's actual real orders
  from FR-306/308 (no synthetic data needed). Also fixed a real bug
  this surfaced: `test/app/shell_test.dart`'s 4-tab shell test hung
  the whole suite on a real network call once the My eSIMs tab became
  real instead of a placeholder — fixed with a missing fake-API
  override, same pattern the file already used for other tabs.
  **FR-403** (eSIM detail — usage) also now passing — the first eSIM
  *detail* screen, adding a tap target + `/my-esims/:id` route on
  FR-402's cards: usage ring, validity countdown, telemetry-stale
  banner, manual refresh via the real `POST /refresh` with a 30s
  client-side cooldown. Real on-device evidence proved the refresh
  call and cooldown both actually work end-to-end. **FR-404** (eSIM
  detail — install section) also now passing — QR reveal, 1-tap
  install double-gated on FR-950's verdict (only the button is gated,
  per Rules.md — QR/manual codes always stay visible), manual SM-DP+/
  matching-ID/LPA copy, "install only once" warning, link to the web
  setup guide. `install_link.dart`/`url_launcher_provider.dart` moved
  from checkout's `application/` into `core/install/` since this logic
  is now shared between FR-310 and this feature. On-device evidence
  used synthetic data (temp-rig) since this screen displays raw LPA/
  matching-ID/SM-DP+ as copyable text — a real screenshot would put
  real secrets on disk even gitignored. **FR-405** (eSIM detail —
  lifecycle status) also now passing — SUSPENDED/REVOKED/CANCELLED/
  EXPIRED replace the entire FR-404 install section with a danger-toned
  banner; the FR-403 usage section above it stays visible regardless.
  New `installAndTopupDisabled()` has no caller yet (FR-407 not built)
  but is tested and ready for reuse. **FR-406** (eSIM detail — history)
  also now passing — `history[]`/`daily_breakdown[]` (VivaPe-only,
  always empty for eSIM Access), rendered generically since no fixed
  item schema is documented anywhere, confirmed against the backend
  source directly. Independent of lifecycle state (shows even under a
  terminal status), unlike FR-404/405's gating. **FR-407** (eSIM detail
  — top-up options) also now passing — gives `installAndTopupDisabled()`
  its first real caller; section hidden when empty or lifecycle-disabled.
  **FR-408** (top-up purchase) also now passing — same wallet/ShurjoPay
  chooser as FR-305/306/307, reused not reimplemented; a real
  password-changed 403 on the ShurjoPay call routes to Set Password
  (same FR-105b pattern, second real gated endpoint in the app). The
  ShurjoPay return for top-up goes to the real **web**, not a custom
  scheme, so it needed its own callback-matching + WebView screen
  (`topup_callback.dart`/`TopupWebViewScreen`), separate from
  checkout's existing one. **FR-409** (share tracking link + receipt)
  also now passing — a share icon sends the real `share_url`; a new
  receipt screen (`/my-esims/:id/print`) shows order no/ICCID/plan/QR,
  captured as a PNG via `RepaintBoundary` and shared the same way (no
  new PDF dependency). `price` omitted — neither endpoint this screen
  touches carries one. **FR-410** (report a problem) also now passing —
  new `support/` data layer, `POST /support/tickets`, category fixed to
  ESIM. The real `order_id` FK isn't available on this screen's data
  path (only `esim_id`/`order_no` are) — embedded in the ticket body
  text instead of guessing a value that would fail the FK constraint.
  My eSIMs (section D cont'd/E) is now fully done through FR-410.
  **FR-501** (section F, public tracking) also now passing — replaced
  the FR-007-era placeholder `TrackingScreen` with a real
  `GET /esims/public/{token}` lookup, reusing `EsimStatus` and FR-403's
  pure usage/validity formatters directly. Deliberately scoped down
  from the authenticated detail screen: no refresh/top-up/report-a-
  problem (all auth-gated), no FR-405 lifecycle banner, no FR-406
  history. **Follow-up flagged by the reviewer, not yet built:** a
  SUSPENDED/REVOKED/CANCELLED/EXPIRED eSIM's public tracker page still
  shows full install codes/QR with no lifecycle warning — the
  authenticated screen gates this via FR-405's banner, the public one
  has no equivalent. Not a blocker for FR-501 (its own FR text doesn't
  mention lifecycle states), but worth a small follow-up fix later.
  Section G (Wallet, FR-601+) is next.
- **Revisit now that checkout + My eSIMs exist:** FR-105b and FR-106 are
  now both **passing** (see Done below). FR-201b stays *partially*
  blocked (needs FR-801 referrals, still not_started). FR-202b stays
  blocked — genuinely backend-side (no featured/price field on the
  country-list endpoint).
- **Real bug found and fixed mid-session (FR-203):** the user asked "why
  can't I see regional packages in buy data?" -- they were visible (Home
  →search/"Buy data" →Regional tab, all 42 real regional packages list
  fine), but completely unbuyable: a regional row's only tap target
  opened the coverage sheet, never the plans screen, even though the
  backend fully supports buying them (confirmed live via curl). Fixed:
  the row now navigates to plans like a normal country; "N countries"
  is its own separate tap target for coverage. See DECISIONS.md.
- **Known backend limitation (not fixable here):** `GET /esims/{id}/status`'s
  `is_installed` telemetry doesn't reliably reflect real install state for
  current eSIM Access profiles — confirmed live with real evidence (see
  "Blocked on backend" below and DECISIONS.md, 2026-11-16/17). The app
  correctly displays whatever the backend reports; this is a backend/
  supplier integration gap, flagged for the backend owner.
- **Active feature:** none.
- **Test device note:** across this session four different physical devices
  were connected at various points (vivo V2344 `10EF1302BJ000R5`, OPPO
  CPH2015 `YP7HDIPFPBWGHM9H`, a third device `109973842B010285`, and a Tecno
  BG6). The vivo has a persistent `flutter_tools`<->`adb` logcat-streaming
  issue that blocks `flutter test integration_test/*.dart -d <device>`
  specifically (plain `adb screencap`/`am start`/`pidof` work fine on it) —
  use whichever device is actually connected, don't assume a fixed serial.
  Also seen on the vivo this session: `adb shell screencap` intermittently
  returns a 0-byte file (SurfaceFlinger gets stuck, logcat shows a stray
  binder-threadpool warning) with no error -- toggling the screen off/on
  once (`adb shell input keyevent KEYCODE_POWER` twice, ~1s apart) reliably
  unsticks it. `adb pull`'s local destination path also needs
  `MSYS_NO_PATHCONV` *unset* (only the remote path needs it set) in this
  Git Bash environment, or it mis-resolves the local file arg.
  New this session: the vivo can also get genuinely stuck ON its own
  lock screen (not just a screencap glitch) -- `adb shell input swipe`
  stopped registering as an unlock gesture, `adb shell wm dismiss-
  keyguard` had no effect either, screen size is 720x1612 so a swipe
  starting below ~y1600 is off-screen and silently clamped/ignored
  (easy to get wrong). If this recurs, physically touch the device
  rather than burning adb retries. One on-device screenshot (FR-501's
  valid-token path) was skipped this session for exactly this reason,
  disclosed rather than faked -- see FR-501's Done entry.
  If a differently-signed debug build is already installed on a newly
  connected device, `adb install -r` fails with
  `INSTALL_FAILED_UPDATE_INCOMPATIBLE`; `adb uninstall co.triptel.app` first.
  Also watch for the device going `unauthorized` after an adb server
  restart — needs a fresh "Allow USB debugging?" tap on the phone.
- **Next step:** FR-105b, FR-106, FR-407, FR-408, FR-409, FR-410, FR-501,
  FR-601 through FR-605, all of **section H (FR-701 through FR-704,
  withdrawals)**, all of **section I (FR-801 through FR-803,
  referrals)**, FR-953b, all of **section K (FR-901, FR-902, guides)**,
  all of **section L (FR-1001 through FR-1003, Account & KYC)**, and
  now **FR-1101** (Support ticket list, opening **section M**) all
  done (see Done below), plus a non-FR UI refresh pass (visual polish
  only, see Done entry). Continuing forward in strict array order,
  next is **FR-1102** (New ticket -- category (no PARTNER), subject,
  body, optional eSIM link, up to 5 attachments ≤ 5 MB each --
  FR-410's existing "Report a problem" flow already creates a ticket
  with no attachments/category picker/optional-link UI; FR-1102 is the
  full standalone "new ticket" form with all of that). FR-201b stays
  blocked -- it needs real eSIM usage data (FR-402/403, already
  passing) AND "the referral promo context (FR-801)"; now that FR-801
  exists, re-check FR-201b's blocker text and consider unblocking it.
- **feature_list.json gotcha found this session:** FR-408's (and likely
  still FR-603's) pre-populated `verification` string required a
  not-yet-written `integration_test/fr_*_test.dart` hitting a real
  money-moving endpoint on every run -- the exact problem already
  documented below (2026-11-14 entry) for FR-306, with FR-408/FR-603
  explicitly flagged as going to hit it too. Fixed FR-408's the same
  way: dropped the integration_test clause, kept the widget tests. If
  FR-603 is reached, check its verification string for the same issue
  before trusting it as given.
- No more user actions pending for Android Google Sign-In. Release builds
  will need a second Android OAuth client for the release keystore's SHA-1
  later; iOS needs its own OAuth client + Associated Domains, out of scope
  without a Mac.

## Done
- 2026-11-17 — UI refresh pass (visual polish only, not tied to a single
  FR). The client sent an 8-panel branded mockup asking to "polish the
  existing UI... throughout the app." The mockup also shows real
  features that don't exist today (AI chat assistant, "Adapter Store",
  "Compare Plans") and a differently-labeled 4-tab bar. Asked the user
  to clarify scope first (two multiple-choice questions) rather than
  guess on something this size -- chose "visual polish only" + "put
  the guidance in Design_System.md." Delivered: Home hero gets a bold
  two-line tagline; two new shared components (`StatusDot`,
  `PromoBanner`) added to the FR-001 gallery but deliberately not wired
  into any real screen yet (no presence indicator or real promo
  content exists to attach them to); `Design_System.md` §5 documents
  what already matched the mockup and, explicitly, everything skipped
  and why (AI assistant/Adapter Store/Compare Plans aren't real FRs;
  nav relabel was out of scope; per-row usage bars would show
  fabricated data since `GET /orders/my-esims` has no live usage
  field, confirmed in `esim_card_shape.dart`; the emoji greeting is
  FR-201b, still blocked). Mockup saved to `docs/design-reference/
  16-client-ui-refresh-reference.png`, with a README section
  distinguishing it from the pre-existing Eskimo layout references
  (different brand, different purpose). 2 new tests (PromoBanner tap,
  Home hero tagline); full suite 569 tests green; `flutter analyze`/
  `dart format` clean; `bash harness.sh verify` green (apk builds).
  Real-device evidence: `artifacts/ui-refresh-home-hero.png` (the real
  Home tab with the new tagline), `artifacts/ui-refresh-gallery-1.png`/
  `-2.png` (the dev-only FR-001 gallery via the established temporary
  local-rig technique, disclosed via a visible DEBUG banner, reverted
  via `git checkout` and confirmed byte-identical). Reviewer: PASS
  after two small doc-accuracy fixes (a wrong `§6` cross-reference in
  two doc comments, meant `§5`; and a dangling "see DECISIONS.md"
  pointer with no matching entry yet, now added). Commit: `b073196`.
- 2026-11-17 — FR-702 passing (withdrawal request with blockers and
  fee preview). New `WithdrawalRequestScreen` is now the real
  destination of the wallet overview's Withdraw button at
  `/wallet/withdraw`; FR-701's `PayoutAccountsScreen` moved one level
  deeper to `/wallet/withdraw/accounts` (matches Architecture.md's
  route table more literally -- `/wallet/withdraw` is the request
  flow, account management is reached from within it). New
  `WithdrawalConfig`/`Withdrawal` models (confirmed field-for-field
  against the real backend source directly) and pure
  `computeWithdrawalFee`/`computeWithdrawalNet` functions mirroring
  the backend's `compute_fee` exactly (PERCENT/FLAT, capped at the
  amount) -- client preview only, the real fee is authoritative
  server-side. Found a real doc-vs-implementation mismatch: API.md
  documents `fee_type` as `PERCENT|FLAT` but the backend source
  (`withdrawal_settings_svc.py`) actually stores/returns it lowercase
  -- handled with a case-insensitive comparison. Blockers shown
  verbatim; "Verify now" for KYC (FR-1002, "coming soon" placeholder)
  and "Add a payout account" at zero accounts both gate correctly on
  their own specific condition, not just "blockers exist".
  **Caught a real bug via my own tests before review:** the account
  picker read `payoutAccountsProvider` with `.whenData(...)` instead
  of awaiting `.future`, which could silently no-op if the provider
  hadn't resolved yet (nothing else on this screen watches it first)
  -- the same `ref.read`-vs-`.future` class of bug this session has
  hit before. Fixed and caught by a screen test that actually drove
  the real async timing, not a trivial `find.text` check.
  25 new tests; full suite 567 green; `flutter analyze`/`dart format`
  clean; `bash harness.sh verify` green (apk builds). Real-device
  evidence is honest about its limits: the real signed-in account is
  itself blocked (no KYC, no payout account), so the blockers-view
  screenshots are genuinely real; the open-form/fee-preview
  screenshots (states the real account can't reach) were captured via
  the established temporary local-`main.dart`-rig technique, disclosed,
  reverted via `git checkout` and confirmed byte-identical before
  rebuilding the real app. Reviewer: PASS, independently confirmed the
  fee formula and the lowercase-`fee_type` discovery against the
  backend source, re-ran the suite and harness verify itself. Commits:
  `b7da380` (feature), `1a4db36` (state).
- 2026-11-17 — FR-703 passing (withdrawal history and cancel pending).
  New `WithdrawalHistoryScreen` at `/wallet/withdraw/history`, linked
  from FR-702's request screen via a new "View withdrawal history"
  action. `Withdrawal` model extended with `id`/`createdAt`/
  `rejectionReason`; `WithdrawalsApi` gained `getWithdrawals`/
  `cancelWithdrawal` (`GET /withdrawals`, `POST /withdrawals/{id}/
  cancel`). Status chips (`withdrawal_status_chip.dart`): PENDING
  warning, PAID success, REJECTED/CANCELLED danger. Cancel on a
  PENDING row confirms via `AlertDialog` first, then calls the real
  API and refreshes via `ref.invalidate`. Rejected rows show the real
  `rejection_reason` text. 11 new tests (7 history screen, 4 status
  chip); full suite 581 green; `flutter analyze`/`dart format` clean;
  `bash harness.sh verify` green (apk builds). Real-device evidence:
  the real signed-in account has no withdrawal history yet, so
  `artifacts/FR-703-history-list.png` (all 4 statuses) and
  `artifacts/FR-703-cancel-confirm-dialog.png` use the established
  temporary local-`main.dart`-rig technique (synthetic data,
  `withdrawalsApiProvider` overridden), disclosed, reverted via `git
  checkout` and confirmed byte-identical before rebuilding the real
  app. **Reviewer: FAIL then PASS** -- first pass caught a real defect:
  `CANCELLED` was shipped as `StatusTone.info` on the claim "only
  cancel returns the held balance, unlike reject," but the reviewer
  checked `D:\eSim\backend\app\services\withdrawal_svc.py` and found
  both `cancel_withdrawal` and `reject_withdrawal` call the same
  `_return_held_balance` -- the justification was false and
  contradicted `Design_System.md`'s already-documented
  Cancelled/Rejected/Failed->danger convention with no doc update to
  back the exception. Fixed to `danger`, screenshot re-captured,
  decision logged in `DECISIONS.md`. Commits: `6b22f77` (feature),
  `7715d0f` (reviewer fix).
- 2026-11-17 — FR-704 passing (withdrawal receipt with share), closing
  **section H (Withdrawals)**. New `WithdrawalReceiptScreen` at
  `/wallet/withdraw/:id/receipt` (`GET /withdrawals/{id}`), reached by
  tapping a row in FR-703's history screen. Shows reference, status
  chip, date, EUR amount/fee/net (shown raw -- deliberately never
  re-converted through the display-currency rate, since a receipt
  should state the authoritative EUR figure), the frozen
  `conversion_rate`/`payout_amount` (in `payout_currency`, shown as
  "Pending approval" rather than fabricated when still null
  pre-approval), account line, payment reference, and rejection
  reason. "Share receipt" reuses FR-409's existing generic
  `receiptSharerProvider` unmodified (RepaintBoundary -> PNG -> native
  share sheet) -- no new sharing code written. New
  `formatRawAmount(amount, currencyCode)` added to
  `currency_format.dart` for displaying an amount already in a
  non-EUR currency without re-converting it (`formatMoney` now calls
  it internally). `Withdrawal` model extended with
  `payoutCurrency`/`conversionRate`/`payoutAmount`/`paymentReference`,
  all nullable, parsed straight from the documented response -- no
  invented fields. **Caught and fixed a real on-device-only bug
  myself, before sending it to review:** the reference-number Row
  (long text next to a `StatusChip`) had no `Expanded`, which
  overflowed by a few pixels at the real device's font scale (visible
  only in a real screenshot, not in the widget test's default surface
  size) -- wrapped in `Expanded`, re-screenshotted clean. 6 new/changed
  tests; full suite 588 green; `flutter analyze`/`dart format` clean;
  `bash harness.sh verify` green (apk builds). Real-device evidence
  (`artifacts/FR-704-receipt.png`) via the established temporary
  local-`main.dart`-rig technique (the real signed-in account's
  withdrawal history is still empty), disclosed, reverted via `git
  checkout` and confirmed byte-identical before rebuilding the real
  app. Reviewer: PASS, independently confirmed the overflow fix is
  present in the committed file, that the "Pending approval" test
  fixture genuinely has null payout fields (not a withdrawal that
  happens to already have one), and that EUR fields never pass through
  rate conversion. Commits: `ea4156a` (feature), `c8a08b5` (state).
- 2026-11-17 — FR-801 passing (refer & earn screen), opening **section I
  (Referrals)** -- new `lib/features/referrals/` data layer from scratch
  (`ReferralSummary`/`ReferralEvent`/`ReferredPerson`/`ReferralReward`
  models, `ReferralsApi.getMe`/`claim`). Screen reached from a new
  "Refer & earn" link on the still-placeholder Account tab (gated
  signed-in-only, same `AuthAuthenticated` switch pattern already used
  for Sign out/Set password there). Eskimo "Free data" card pattern
  (`docs/design-reference/10-rewards-referral.png`) re-skinned in
  Triptel tokens: `BalanceCard` for promo balance/total earned/people
  joined, code chip + Invite (shares the real `share_url` via the
  existing `SharePlus.instance` pattern, no new dependency), "how it
  works" with real per-event referrer/referred amounts (`NEW_MERCHANT`
  filtered out at the model layer -- merchant-only, per API.md §8),
  referred-people/rewards lists with empty states. `is_enabled:false`
  hides the whole programme behind an `EmptyState` rather than a
  zeroed-out real UI. FR-802 (claim)/FR-803 (pre-fill) deliberately not
  built -- `claim()` exists on the API unused, no `can_claim`/
  `referred_by` UI. **Caught and fixed a real widget-test layout bug
  myself before review:** `PillButton`'s primary/secondary variants set
  `minimumSize: Size.fromHeight(56)` (infinite width) unconditionally,
  regardless of `fullWidth` -- broke the Invite button sitting next to
  an `Expanded` code chip in a `Row` (every other `fullWidth: false`
  call site in this codebase happens to use `variant: text` or sit
  outside an unconstrained `Row`, so this was never hit before); fixed
  with an explicit `SizedBox(width: 110, ...)` wrapper, documented
  inline. 11 new/changed tests; full suite 598 green; `flutter
  analyze`/`dart format` clean; `bash harness.sh verify` green (apk
  builds). **Real-device evidence is genuinely mixed, disclosed
  honestly:** `artifacts/FR-801-refer-earn.png` is real (the real
  signed-in account's live beta data) and happens to show
  `is_enabled:false` -- this beta account's referral programme is
  actually disabled server-side, so that EmptyState screenshot is
  authentic, not simulated. The populated-stats/list views
  (`-stats.png`/`-rewards.png`) couldn't be captured from this account
  for that reason, so they use the established disclosed local-
  `main.dart`-rig technique (synthetic `ReferralSummary`, 2 referrals/
  rewards); `lib/main.dart` restored and confirmed byte-identical
  before/after, real app rebuilt+reinstalled afterward. Reviewer: PASS,
  independently confirmed `NEW_MERCHANT` filtering and `is_enabled`
  gating are enforced at the data/widget-branch level (not just UI
  dressing), the layout fix is correct and sufficient (110px is enough
  for "Invite" at `FittedBox` scale), and no FR-802/803 scope crept in.
  Commits: `b2bab24` (feature), `8669bd7` (state).
- 2026-11-17 — FR-802 passing (claim a referrer while `can_claim`). Added
  a code field + Claim button to the refer & earn screen, visible only
  while `GET /referrals/me`'s `can_claim` is true (`_ReferEarnBody`
  converted to a `ConsumerStatefulWidget` to hold the form state).
  `POST /referrals/claim` on submit; success clears the field and calls
  `ref.invalidate(referralSummaryProvider)` -- a real server re-fetch,
  not client-side hiding, so the form only disappears once the backend
  actually flips `can_claim` to false. A real 4xx (already has a
  referrer/invalid/self/after first purchase) shows the server's own
  message and the form stays for retry; a 3-16 char client-side check
  is a UX nicety only, never a substitute for real server error
  handling. 3 new tests; full suite 601 green; `flutter analyze`/`dart
  format` clean; `bash harness.sh verify` green. Non-vacuousness proof:
  flipped the `can_claim` condition to its inverse, confirmed 3 real
  test failures, reverted. Real-device evidence via the established
  disclosed local-`main.dart`-rig technique -- the real signed-in
  account's referral programme is `is_enabled:false` (confirmed live in
  FR-801), so `can_claim` can never be exercised against the real
  account; `lib/main.dart` restored and confirmed byte-identical before/
  after, real app rebuilt+reinstalled afterward. Reviewer: PASS,
  independently confirmed the condition isn't inverted, the re-fetch is
  real (not local state), the form survives a failed submit for retry,
  and no FR-803/`referred_by` scope crept in. Commits: `230fba9`
  (feature), `efa61fa` (state).
- 2026-11-17 — FR-803 passing (referral link pre-fill + validate),
  closing **section I (Referrals)**. The register screen's referral-
  code field already pre-filled from a `?ref=` link (FR-007, untouched
  by this change) -- what FR-803 added is live validation against the
  public `GET /referrals/validate`, 400ms debounced (same pattern as
  the catalog search sheet's debounced search): "Invited by @user, you
  get €X" (success colour) or "This referral code is not valid."
  (danger colour), with a race guard so a slow response for a since-
  changed code is discarded, and clearing the field clears the message
  immediately (no stale state). New `ReferralValidation` model +
  `ReferralsApi.validate(code)`. 5 new tests; full suite 606 green;
  `flutter analyze`/`dart format` clean; `bash harness.sh verify`
  green. **Real-device evidence is genuinely mixed, disclosed
  honestly:** validating this beta account's own real code `ALICE12`
  against the live beta API for real returned `valid:false` --
  consistent with FR-801's separately-confirmed finding that this
  account's referral programme is `is_enabled:false` server-side
  (expected, not a bug). No real valid code is obtainable from this
  account, so the "Invited by @bob" success-state screenshot uses the
  established disclosed local-`main.dart`-rig technique; `lib/main.dart`
  restored and confirmed byte-identical before/after, real app
  rebuilt+reinstalled afterward. Reviewer: PASS, independently confirmed
  the debounce race-guard logic, that the pre-fill block is byte-
  identical to before this commit, and caught a real process gap --
  FR-803's `verification` command only covered `test/features/
  referrals`, missing `test/features/auth/register_screen_test.dart`
  where the feature's primary tests actually live (so reverting the
  feature wouldn't have failed the stated command) -- fixed before
  marking passing. Commits: `d4fedab` (feature), `d93ba4f` (state).
- 2026-11-17 — FR-953b passing (compatibility gate wired into checkout/
  eSIM detail). Investigated before writing any new code, since its
  dependencies (FR-301/FR-310/FR-404) were all already passing: both
  `runPreCheckoutCompatibilityGate` (FR-301) and the install-gating
  (FR-404/FR-310, `verdict.kind == supported` gates the one-tap
  install button/link) were ALREADY wired into their real call sites
  (`destination_plans_screen.dart`, `esim_detail_screen.dart`,
  `purchase_success_screen.dart`) as a natural consequence of building
  those features correctly from day one -- `Rules.md`'s "compatibility
  never blocks, only gates install" was a hard constraint followed
  throughout, not retrofitted. The one real gap: no end-to-end test
  proved the checkout-side wiring actually fires from
  `destination_plans_screen`'s real Continue button --
  `pre_checkout_gate_test.dart` only tested the gate function in a bare
  harness, and `destination_plans_screen_test.dart` (where such a test
  belongs) sat outside FR-953b's original `verification` command's
  scope (`test/features/catalog`, not `checkout`/`esims`). Added 2
  end-to-end tests there and extended the verification command to
  include that file. FR-404/FR-310 already had equivalent real
  end-to-end gating tests in their own test files -- confirmed by
  reading them, no gap there. Non-vacuousness proof: temporarily
  short-circuited the gate's not-supported branch to always proceed,
  got 3 real failures, restored via `git checkout` (confirmed
  untouched in the final commit). Full suite green; `flutter analyze`/
  `dart format` clean; `bash harness.sh verify` green. Real-device
  evidence is genuine: this connected device has no eSIM hardware
  (confirmed originally when FR-301 was built), so live-tapping
  Continue on a real Japan plan for real shows the actual "Buy Now,
  Use Later!" dialog end-to-end (Home -> Japan -> select plan ->
  Continue) -- the same real behavior FR-301/FR-404/FR-310 already
  captured in their own evidence, now with a fresh confirming
  screenshot and a regression test that would catch it breaking.
  Reviewer: PASS, independently confirmed the wiring claims by reading
  all three call sites directly, confirmed FR-301/FR-310/FR-404 were
  genuinely already passing with real evidence (not marked passing
  prematurely to dodge this FR), and confirmed `pre_checkout_gate.dart`
  is untouched in the final commit. Commits: `1fe7135` (feature),
  `d49c7d2` (state).
- 2026-11-17 — FR-901 passing (eSIM setup guide), opening **section K
  (Guides & help)**. New `lib/features/guides/` from scratch. Content
  ported line-by-line from the real web app's static
  `guides/esim-setup-guide` page (`D:\eSim\frontend\src\app\guides\
  esim-setup-guide\page.tsx`) -- iOS/Android numbered steps,
  install-once warning, troubleshooting checklist, link to FR-952's
  supported-devices list. No backend endpoint needed (static copy,
  identical on both platforms). Replaced FR-404's previous "launch the
  web page in an external browser" placeholder on the eSIM detail
  screen's "View setup guide" link (that placeholder was explicitly
  documented as temporary in FR-404's own evidence notes, pending this
  screen existing) -- now navigates in-app; deleted the now-dead
  `esim_install_links.dart`/`setupGuideUrl()` and its test. Full suite
  green; `flutter analyze`/`dart format` clean; `bash harness.sh
  verify` green. Real-device evidence is genuine: reached via real
  navigation (My eSIMs -> a real eSIM -> View setup guide), screens
  show the actual ported content live. **Reviewer: FAIL then PASS** --
  first pass diffed the port against the real web source directly and
  caught two real, silently-dropped Support references: the
  troubleshooting list was missing "Still stuck? Contact Support with
  your order number." and the install-once warning was missing "...and
  contact Support before removing it." Both had been deleted rather
  than disclosed, even though no general `/support` screen exists yet
  (FR-1101/1102 `not_started`, only FR-410's per-eSIM report-problem
  does) -- this session's own established convention is to disclose
  such a forward-dependency gap, not silently delete the instruction.
  Fixed by restoring both as plain text (no route to link to yet) with
  an inline comment explaining why; re-verified, re-captured both
  screenshots live showing the restored text. Commits: `18779e0`
  (feature), `09d63f1` (reviewer fix), `043f80f` (state).
- 2026-11-17 — FR-902 passing ("New to eSIM?" sheet), closing **section
  K (Guides & help)**. No documented web/Eskimo source for this exact
  sheet (checked the frontend source and `docs/design-reference/` --
  the closest screenshot, `15-help-sheet.png`, is FR-1104's separate
  AI-assistant sheet, confirmed via the design-reference README), so
  content was designed fresh from the one-line FR spec, built on the
  existing `coverage_sheet.dart` bottom-sheet pattern rather than
  inventing new chrome. Short explainer of what an eSIM is + "View
  setup guide" (FR-901) and "Check device compatibility" (FR-952)
  buttons, both popping the sheet before pushing the real route; a
  plain-text "Contact Support" line since no general `/support` screen
  exists yet -- same disclosed-limitation convention just established
  fixing FR-901 earlier today. Entry point: a "New to eSIM?" link in My
  eSIMs' empty state (shown only with zero eSIMs) -- the natural place
  a first-time user would want this explained; FR-902's spec names no
  entry point, so this was a judgment call, not a documented
  requirement. 5 new/changed tests; full suite 615 green; `flutter
  analyze`/`dart format` clean; `bash harness.sh verify` green.
  Non-vacuousness proof: temporarily pointed the setup-guide button at
  a wrong route, confirmed a real test failure, restored. Real-device
  evidence via the established disclosed local-`main.dart`-rig
  technique (the real signed-in account already has eSIMs, so the
  empty-state entry point can't be reached live); `lib/main.dart`
  restored and confirmed byte-identical before/after, real app
  rebuilt+reinstalled afterward. Reviewer: PASS, independently
  confirmed pop-before-push navigation, that both hardcoded route
  strings match the real router's registered paths, that the Support
  line is genuinely inert (no tap handler), and that no scope crept
  beyond the 4 changed files. Commits: `5e3dcf0` (feature), `422d185`
  (state).
- 2026-11-17 — FR-1001 passing (real Account screen), opening
  **section L (Account & KYC)** -- replaces the `AccountScreen`
  placeholder that's stood in since FR-101. Greeting `BalanceCard`
  (username, real DEFAULT wallet balance, REWARD stat -- reusing
  FR-601's existing `walletBalance()` helper verbatim) + "Invite
  friends" CTA pushing `/refer`, which consolidates FR-801's earlier
  standalone "Refer & earn" button into this one real entry point
  (same destination, no functionality lost, confirmed by the
  reviewer against FR-801's own commit history). 4 `ListGroup`s:
  **Account** (Profile -> coming-soon/FR-1002; Identity verification
  -> the REAL `GET /kyc/me` status, a deliberately minimal read --
  the write/submission flow stays FR-1003's separate scope, judged
  defensible by the reviewer against both FRs' actual spec text),
  **Settings** (Language/Currency rows embedding the existing header
  pill switchers via a new `_SwitcherRow`, justified since `ListRow`
  has no trailing-widget slot), **Support** (Check device
  compatibility -> real FR-952; Setup guide -> real FR-901; Help/
  Support tickets -> coming-soon/FR-1101; Track an eSIM -> a new
  dialog accepting a full tracking link or bare token, reusing FR-007's
  existing deep-link parser to extract the token either way), **About**
  (Legal documents -> coming-soon/FR-1201; Version -> real
  `PackageInfo.fromPlatform()`, never hardcoded). New minimal
  `lib/features/kyc/` data layer (read-only, `GET /kyc/me` only). 26
  new/changed tests; full suite 638 green; `flutter analyze`/`dart
  format` clean; `bash harness.sh verify` green. Non-vacuousness proof
  on `resolveTrackingToken`: hardcoded a wrong return value, confirmed
  a real test failure, reverted. Real-device evidence is genuinely
  real, no rig needed: live navigation to the Account tab shows the
  actual signed-in balance, the real "Not verified" KYC status, the
  real app version (`1.0.0 (1)`), and the real native Track-an-eSIM
  dialog. (One hiccup this session, not feature-related: the USB-
  connected test device dropped its adb connection mid-session --
  `adb devices` came back empty, `adb kill-server`/`start-server`
  didn't help, it reconnected on its own a few minutes later; the
  device-check run that happened to straddle the disconnect silently
  produced a stale APK install, caught by noticing the on-device
  screenshot still showed the OLD placeholder text -- re-ran
  `device-check` once the device was back and got the real screen.)
  Reviewer: PASS (initial attempt stalled/failed with no output after
  600s, re-dispatched fresh and it completed normally on retry) --
  independently confirmed the wallet-type lookups aren't swapped, the
  KYC subtitle genuinely reflects async state, Cancel never navigates,
  the FR-801 consolidation loses no functionality, the KYC read stays
  within FR-1001's own scope, no FR-1002/1101-1104 UI leaked beyond
  inert coming-soon snacks, and no regressions in FR-801/FR-601's own
  suites. Commits: `c21d371` (feature), `b311b7f` (state).
- 2026-11-17 — FR-1002 passing (Profile view/edit phone, change
  password). New `ProfileScreen` at `/profile` (`GET /auth/me`):
  avatar (real `avatar_url` or a plain icon fallback -- no upload UI,
  no endpoint is documented for it), name/username, email + a real
  `StatusDot` badge driven by `email_verified`, a Google-linked row
  shown only when `has_google` is true, phone edit (`PUT /auth/me/
  preferences` sending only `{"phone"}` -- never touching the separate,
  already client-local-only `preferred_currency` preference from
  FR-005/006), and a "Change password" button that reuses FR-105's
  existing `/set-password` screen as-is rather than duplicating its
  logic. `CurrentUser` extended with `phone`/`fullName`/
  `isKycVerified`/`avatarUrl`/`emailVerified`/`hasGoogle` per the full
  documented `GET /auth/me` shape. The Account tab's "Profile" row
  (previously a coming-soon snack) now navigates here for real. 10 new
  tests + 1 navigation test + 6 trivial `updatePhone` stub overrides
  added to pre-existing `AuthApi` fakes elsewhere; full suite 649
  green; `flutter analyze`/`dart format` clean; `bash harness.sh
  verify` green. Non-vacuousness proof: inverted the email-verified
  ternary, confirmed a real test failure, reverted. **Real-device
  evidence required redaction:** live navigation to the real Profile
  screen showed the real signed-in account's actual avatar photo, full
  name, email, and phone number -- genuine evidence, but since this
  repo is public, the raw screenshot was redacted (solid boxes over
  the avatar/name/username/email/phone) with Python/Pillow before
  saving to `artifacts/`, keeping only the UI structure/badges/buttons
  visible. Reviewer: PASS, independently confirmed `updatePhone` sends
  only the phone field, the post-save refresh is a real re-fetch (not
  optimistic local state), the avatar/Google-row conditionals are
  genuinely absent (not just hidden) when false, and the 6 touched
  auth test files each got only a trivial 3-line stub with nothing
  else changed. Commits: `49100a9` (feature), `b3c8b52` (state).
- 2026-11-17 — FR-1003 passing (KYC status and submission), closing
  **section L (Account & KYC)**. New `KycScreen` at `/kyc`: real status
  display (reusing FR-1001's `kycStatusLabel`), real `rejection_reason`/
  `submitted_at` shown when present, an NID field, required front photo
  + optional back photo (`image_picker`'s first real use in this
  codebase, via a new `kycImagePickerProvider` seam mirroring the
  existing `urlLauncherProvider`/`topupLauncherProvider` pattern so
  tests never drive the real platform channel), and Submit for review
  -> `POST /kyc/submit` multipart (`document_back` genuinely omitted
  from the form, not sent null, when no back photo is picked). APPROVED
  shows a plain success state with no form; PENDING/REJECTED/not-
  submitted all fall through to the form, matching the API's
  documented resubmission-resets-to-PENDING behavior. Post-submit, the
  screen does a real re-fetch (`ref.invalidate(kycStatusProvider)`),
  never a locally-faked status. The Account tab's "Identity
  verification" row (previously a coming-soon snack, per FR-1001's own
  scope note) now navigates here for real. 10 new/changed tests; full
  suite green; `flutter analyze`/`dart format` clean; `bash harness.sh
  verify` green. Non-vacuousness proof: changed the APPROVED gate's
  string comparison to a non-matching value, confirmed 2 real test
  failures, reverted. **Real-device evidence deliberately stops short
  of a real submission:** live navigation reaches the real form
  showing the real account's genuine "Not verified" status, and a real
  client-side validation snackbar fires correctly ("Enter your NID
  number.") -- did NOT submit a real NID/document photo, since that
  would be an irreversible real submission of personal ID data to the
  live beta backend with no way to undo it; the actual `POST /kyc/
  submit` call itself is covered by the test suite's fakes instead.
  Reviewer: PASS, independently confirmed the multipart omission of
  `document_back`, the APPROVED-only gate against all four real status
  combinations, that the image-picker seam is never bypassed to a real
  platform channel in any test, and flagged one cosmetic stale doc
  comment (fixed in a same-day follow-up, `77bedac`) -- no functional
  issues. Commits: `39f842d` (feature), `77bedac` (doc fix), `3956176`
  (state).
- 2026-11-17 — FR-1101 passing (support ticket list), opening
  **section M (Support)**. New `SupportTicketListScreen` at `/support`
  (`GET /support/tickets`): reference, subject, status chip, last
  activity (`last_message_at`, falling back to `created_at` --
  confirmed against the real backend model that `last_message_at`
  genuinely drives queue ordering). `SupportTicket` extended with
  `order_id`/`created_at`/`last_message_at`/`resolved_at`/`closed_at`
  per the full documented shape (FR-410's existing create flow only
  needed the narrower subset). New `ticketStatusChip` pure function.
  `TriptelScaffold(scrollable: false)` since the screen hosts a
  `ListView` directly. Account tab's "Help / Support tickets" row now
  navigates here instead of a coming-soon snack; rows aren't tappable
  yet (FR-1103's thread screen isn't built). 9 new/changed tests; full
  suite 667 green; `flutter analyze`/`dart format` clean; `bash
  harness.sh verify` green. Non-vacuousness proof: forced the last-
  activity fallback to always use `created_at`, confirmed a real test
  failure, reverted. Real-device evidence is genuine: live navigation
  to the real signed-in account's Support screen shows its actual
  real ticket (`TKT-261110-9A1CD`, created earlier this session via
  FR-410) with its real "Answered" status and timestamp. **Reviewer:
  FAIL then PASS** -- first pass caught that `CLOSED` and `OPEN`
  shared the identical `info` tone (making opposite ends of the
  ticket lifecycle look visually the same in a skimmed list) AND that
  the code's own comment claimed a `DECISIONS.md` entry existed for
  this judgment call when none did. Fixed `CLOSED` to `danger`
  (matching the existing Cancelled/Expired/Failed terminal-state
  convention) and added the missing `DECISIONS.md` entry; re-verified.
  No screenshot re-capture needed -- the real evidence shows
  `ANSWERED`, untouched by the fix. Commits: `dafb9a5` (feature),
  `39c5dd3` (reviewer fix), `de7db48` (state).
- 2026-11-17 — FR-701 passing (payout accounts CRUD, max 5), opening
  **section H (Withdrawals)** -- built from scratch, no pre-existing
  data layer (unlike wallet's FR-305/306 head start). New
  `PayoutAccount` model, `WithdrawalsApi` (getAccounts/addAccount/
  setDefaultAccount/deleteAccount against the real `GET/POST/POST
  .../default/DELETE /withdrawals/accounts` endpoints, confirmed
  field-for-field against the real backend source directly). New
  `ApiClient.delete()` -- the client's first DELETE verb. Two screens:
  `PayoutAccountsScreen` (list, tap a card for a bottom sheet with Set
  as default/Delete, a real `AlertDialog` delete confirmation, a
  disabled Add button with a real inline message at 5 accounts) and
  `AddPayoutAccountScreen` (Bank/Mobile toggle hides branch_name/
  routing_number for Mobile -- a bKash/Nagad wallet genuinely has
  neither, even though the backend accepts them for either type).
  Fixed a real layout bug caught by my own tests before review:
  `PayoutAccountsScreen`'s `Expanded` doesn't work inside
  `TriptelScaffold`'s default scrollable wrapper (unbounded height) --
  fixed with `scrollable: false`, same precedent as the earlier
  `LedgerScreen` fix. 20 new tests; full suite 546 green; `flutter
  analyze`/`dart format` clean; `bash harness.sh verify` green (apk
  builds). Real-device evidence, full CRUD lifecycle genuinely
  exercised end-to-end against the live beta backend: real empty
  state -> added a real BANK account (auto-defaulted, confirmed
  against the backend's "first account becomes default" logic) ->
  added a real MOBILE account -> switched the default to it via a
  real tap -> deleted both, restoring the account to its original
  empty state (cleanup, since this is the real signed-in beta
  account). Reviewer: PASS, independently reproduced the
  non-vacuousness test and the scrollable/Expanded bug claim, re-ran
  the full suite and harness verify itself. Commits: `cdf74c1`
  (feature), `427ec64` (state).
- 2026-11-17 — FR-605 passing (top-up result states), **closing out
  section G (Wallet) entirely.** FR-603's gateway WebView previously
  collapsed the terminal redirect to a bool (failed/cancelled vs.
  success), losing the distinction this FR explicitly wants. New
  `WalletTopupResult` (status: success/failed/cancelled, optional
  reason) + `parseWalletTopupCallback(uri)` replace the old bool
  function; `WalletTopupScreen` now shows three distinct messages
  ("Top-up successful." pops back to the wallet overview; "Top-up
  cancelled."/a human failure reason both stay on the screen so the
  user can retry). New `walletTopupFailureReasons` map covers all 6
  reason codes the backend's `payments.py _fail(...)` calls actually
  send on the `/wallet` redirect path (confirmed by reading the
  backend source directly: not_paid, unexpected_response,
  unknown_order, malformed_order, unknown_user, no_wallet), with an
  honest raw-code fallback for anything undocumented.
  **Found a real third-party bug live on-device while verifying
  this:** ShurjoPay's own sandbox "Do you want to cancel this
  transaction? Click Here" link malforms its own redirect query
  string -- joins params with a second `?` instead of `&`, so the raw
  value comes through as `cancelled?order_id=...`, not a clean
  `cancelled`. A naive equality check would have silently
  misclassified every real cancellation as a generic failure.
  Confirmed by temporarily adding a debug print of the intercepted
  URI, triggering the real cancel link on the real device, and
  reading the real value back via `adb logcat`; fixed by taking the
  leading token before any `?`; removed the debug print before
  committing. 14 new/changed tests including a regression test using
  the exact malformed string observed live. Full suite 528 tests
  green; `flutter analyze`/`dart format` clean; `bash harness.sh
  verify` green (apk builds). Real-device evidence:
  `artifacts/FR-605-cancelled-result.png` (the real "Top-up
  cancelled." snackbar, captured after the fix -- the same real
  action produced the wrong "Top-up failed." before it, confirmed
  during diagnosis but not committed as evidence since it documents
  the bug, not the passing feature). Reviewer: PASS, independently
  reproduced the bug/fix and re-ran the full suite + harness verify
  itself. Commits: `b2d90f2` (feature), `0ed94a2` (state).
- 2026-11-17 — FR-604 passing (manual deposit to a configured method).
  New ManualDepositScreen (`/wallet/manual-deposit`, reached via a
  "Pay by bKash / bank transfer instead" link on FR-603's top-up
  screen). Method selection reuses the pre-existing `PaymentMethodSheet`
  widget against the real `/settings/public.payment_methods` (new
  `PaymentMethod` model, new `PublicSettings.paymentMethods`/
  `banglaQrImage` fields with safe fallbacks for old cached data).
  New `resolveApiUrl()` helper (`lib/core/network/absolute_url.dart`)
  turns the backend's server-relative upload paths (e.g.
  `bangla_qr_image`) into real URLs using only `Env.apiBaseUrl`'s
  scheme+host -- confirmed live via curl that the resolved URL
  actually serves the real image. Amount fixed to BDT (every
  configured method here is a Bangladesh domestic transfer method, so
  a currency picker would have no real use -- judgement call) +
  transaction ID -> `POST /wallets/manual-deposit` (new
  `WalletsApi.submitManualDeposit`, new `ManualDeposit` model). No
  endpoint lists past deposits (API.md §5) -- the result IS the
  "pending admin approval" message.
  Caught and fixed a UX issue myself before review: initially reused
  the shared `ListRow` widget (always shows a chevron, implying
  tappability) to display static account-detail fields; replaced with
  a local, non-interactive info row instead of touching the shared
  widget's other, genuinely tappable call sites.
  **Reviewer caught a real evidence-accuracy gap (round 1 FAIL):** the
  evidence notes claimed a screenshot showed the form filled in, but
  neither referenced screenshot actually did -- both showed empty
  fields. Fixed by capturing a genuine on-device screenshot of the
  filled form (Amount 500, Transaction ID FR604TEST001, floating
  labels confirming real typed text) and correcting the notes. Round 2
  re-review: PASS.
  21 new tests; full suite 521 tests green; `flutter analyze`/
  `dart format` clean; `bash harness.sh verify` green (apk builds).
  Real-device evidence: `artifacts/FR-604-manual-deposit-screen.png`,
  `artifacts/FR-604-manual-deposit-method-selected.png` (real
  configured "bKash Account" with its real account number and the
  real branding image served at the resolved `bangla_qr_image` URL),
  `artifacts/FR-604-manual-deposit-form-filled.png`. Did NOT tap
  Submit: the auto-mode permission classifier blocked it as a real
  financial submission against the live beta backend, same category
  as FR-603's blocked card-data entry -- disclosed, not worked around.
  Commits: `2e94fbb` (feature), `cdf91c5` (state).
- 2026-11-17 — FR-603 passing (wallet top-up via ShurjoPay). New
  WalletTopupScreen (`/wallet/topup`, pushed from the wallet overview's
  now-real Top up button) with 4 fixed EUR presets (5/10/20/50)
  converted to the user's currency plus a custom amount field; limits
  text from new `PublicSettings.topupMin`/`topupMax` fields (parsed
  from the real `topup_min`/`topup_max`, safe defaults for old cached
  bootstrap data). `POST /payments/shurjopay/topup?amount=X&currency=Y`
  (new `WalletsApi.initiateTopup`, new `TopupCheckout` model) opens the
  real `checkout_url` in a new WebView screen -- same established
  Gateway WebView pattern as FR-307/FR-408 -- via a new
  `walletTopupLauncherProvider` seam. New `isWalletTopupCallbackUrl`/
  `walletTopupCallbackFailed` intercept the backend's real terminal
  redirect (confirmed by reading `app/api/v1/payments.py` directly):
  `.../wallet?topup=success|failed|cancelled` -- `cancelled` is the
  gateway's own direct redirect on `SHURJOPAY_CANCEL_URL` when the
  customer backs out before our backend callback ever runs, treated
  the same as a failure. A real password-changed 403 routes to Set
  Password, same guard as every other money-moving action. On success,
  invalidates `myWalletsProvider`/`ledgerProvider` so the overview and
  history reflect the new balance.
  **Reviewer caught a real bug (round 1 FAIL):** the screen collapsed
  `AsyncError` into the same "not ready" state as `AsyncLoading` for
  its three async providers, so a failed settings/rate fetch trapped
  the user on an infinite spinner with no error or retry -- every
  sibling wallet/esim/catalog screen has this. Fixed by watching each
  `AsyncValue` directly and adding the standard `ErrorState`+retry;
  added a regression test that reproduces the bug (forces
  `bootstrapProvider` to throw, confirms `pumpAndSettle` would time out
  pre-fix) before confirming the fix. Round 2 re-review: PASS.
  508 tests green (up from 487); `flutter analyze`/`dart format`
  clean; `bash harness.sh verify` green (apk builds).
  Real-device evidence: `artifacts/FR-603-topup-screen.png` (real
  converted BDT limits/presets from the real account's settings),
  `artifacts/FR-603-shurjopay-webview.png` (the real ShurjoPay sandbox
  checkout page, "Payment to Sandbox 705 BDT", a real sandbox order
  ID -- confirms the full initiate-and-launch path against live beta).
  Didn't complete a real sandbox payment: typing test card details
  into the gateway's own hosted form was blocked by the auto-mode
  permission classifier as resembling payment-data submission, so the
  terminal callback itself is verified by unit tests against the
  backend-documented redirect rather than a completed live transaction
  -- disclosed, not worked around. Backing out of the WebView (the X
  button) was verified live: returns cleanly with no false message.
  Commits: `241b871` (feature), `fca5799` (state).
- 2026-11-17 — FR-602 passing (transaction history). New LedgerScreen
  at `/wallet/history` (pushed from a "View transaction history" link
  added to the wallet overview), backed by `GET /wallets/ledger`
  (new `WalletsApi.getLedger(walletType, limit)`, new `LedgerEntry`
  model). Filter by wallet type is a real server re-query (confirmed
  against the backend: ledger rows carry no `wallet_type` field
  themselves, so client-side re-filtering of cached rows would have
  been wrong) via a `SegmentedPill` (All/Main/Reward/Commission).
  Human labels for all 12 documented `reference_type` values with an
  honest raw-value fallback for anything undocumented. Credit/debit
  colouring (green "+"/red "-"; the backend always sends a positive
  `amount` magnitude, sign comes from `tx_type`, confirmed by reading
  `finance_svc.py` directly). Found and fixed a real layout bug live
  on-device: the shared `SegmentedPill` widget's 4 fixed-padding
  segments overflowed the track on this phone -- fixed locally in
  `LedgerScreen` only (wrapped in a horizontal scroll) rather than
  touching the shared widget, since its other 4 call sites all use
  2-3 short labels and rely on its current wrap-content sizing.
  Fixture captured from the real signed-in account via a temporary,
  never-committed debug print (curl-based test-account registration
  was blocked by the auto-mode permission classifier this time --
  noted below). 10 new tests; full suite 487 green; `flutter analyze`
  clean; `dart format` clean; `bash harness.sh verify` green.
  Real-device evidence: `artifacts/FR-602-ledger-list.png` (real DEBIT
  rows in red), `artifacts/FR-602-ledger-credit.png` (a real REFUND
  CREDIT row in green, from an actual provisioning-failure refund on
  this account). Reviewer: PASS, independently re-verified against the
  backend source and re-ran the suite itself. Commits: `89dab2b`
  (feature), `abf3fa1` (state).
- 2026-11-17 — FR-601 passing (wallet overview). Replaced the wallet
  tab's placeholder with the real `GET /wallets/my-wallets` balance
  hero card (DEFAULT main balance, REWARD always shown "not
  withdrawable", COMMISSION only when > 0), reusing the pre-existing
  wallet data layer and the previously-unused `BalanceCard` widget --
  its first real producer. Top up/Withdraw/Refer show real "coming
  soon" snacks (FR-603/701+/801+ don't exist yet). Found and fixed a
  real, visible layout bug in the shared `PillButton`: three
  equal-width buttons in a Row wrapped "Withdraw" mid-word onto two
  lines -- fixed globally with `FittedBox(fit: scaleDown)`, verified
  against the full suite (no regressions). Also fixed
  `test/app/shell_test.dart`'s missing `walletsApiProvider` fake
  override (same pattern as the My eSIMs tab fix). 477 tests green,
  `flutter analyze` clean, `bash harness.sh verify` green. Real-device
  evidence: `artifacts/FR-601-wallet-overview.png`,
  `artifacts/FR-601-coming-soon-snack.png` (real account, real BDT
  balances). Reviewer: PASS, with one advisory nuance logged in
  DECISIONS.md about the ref.watch-vs-ref.read fix not being provably
  load-bearing from current tests. Commits: `dfa0171` (feature),
  `b3c7aa7` (state).
- 2026-11-17 — Session 10 continued (FR-501, public eSIM tracking by
  token without login):
  - Replaced the FR-007-era `TrackingScreen` placeholder with a real
    `GET /esims/public/{token}` lookup -- new `lib/features/tracking/`
    data layer reusing the existing `EsimStatus` model (API.md section
    7: "same shape" as the authenticated endpoint, `share_url` always
    null) and FR-403's existing pure usage/validity formatters.
  - Shows product title, status, usage ring, validity, the QR, and
    manual install codes -- a gift recipient without an account still
    needs to install it. Deliberately NOT replicated: refresh/top-up/
    report-a-problem (all auth-gated), FR-405's lifecycle banner,
    FR-406's history section -- kept this a focused read-only view.
  - Invalid token's 404 shows the real message + Support contacts,
    reusing FR-109's suspended-screen pattern.
  - Fixed an unrelated test gap this surfaced: FR-007's own routing
    test asserted against the old placeholder's literal text and
    didn't mock the tracking API -- fixed to check the real widget's
    `token` property with a proper fake override.
  - 11 new/changed tests; full suite (466 tests) green, `flutter
    analyze` clean, `bash harness.sh verify` green. Non-vacuous:
    disabled the Support-contact box's null-guard, got a real failure,
    restored.
  - On-device evidence is PARTIAL, disclosed: a real invalid-token deep
    link against the real rebuilt app correctly shows "Not found" +
    real support contacts. The valid-token path (needs the synthetic-
    data rig since it shows a real QR/LPA) could NOT be screenshotted
    -- the test device got stuck on its own lock screen (see the
    device-quirks note above). Relied on the 5 passing widget tests
    covering that render path instead of fabricating or skipping it.
  - Reviewer: PASS. Flagged one real, non-blocking follow-up: a
    SUSPENDED/REVOKED/CANCELLED/EXPIRED eSIM's public tracker shows
    full install codes with no lifecycle warning (the authenticated
    screen gates this via FR-405; the public one doesn't). Worth a
    small fix later, not required by FR-501's own text.
  - Commits: `f9ed3b9` (feature code), `97e7b90` (state → passing).
- 2026-11-17 — Session 10 continued (FR-410, report a problem for an
  eSIM):
  - New `lib/features/support/` data layer: `SupportTicket` model (real
    fixture captured via a live, read-only `GET /support/tickets` call
    -- a pre-existing ticket from earlier session testing), `SupportApi
    .createTicket()` (`POST /support/tickets`, multipart via dio's
    `FormData`, no files).
  - New `ReportProblemScreen` reachable from a "Report a problem" link
    on the eSIM detail screen (placed always-visible, not gated by
    lifecycle status -- Rules.md only disables install/top-up on a
    terminal status, reporting a problem is neither). Subject prefilled
    with the real order no, category fixed to `ESIM` (not a picker --
    the general new-ticket flow with a real picker is FR-1102, not
    built).
  - Real backend constraint found and worked around: `order_id` is a
    genuine FK to `orders.id` (confirmed in the backend source), but
    neither `GET /esims/{id}/status` nor `GET /orders/my-esims` exposes
    that UUID anywhere -- only `esim_id`/`order_no` are available on
    this screen's data path. Sending `order_no` into that FK would
    likely violate it. Omitted the structured field; embedded the plan
    title/order_no/esim_id in the ticket body's own text instead, which
    support staff can still read.
  - 9 new tests; full suite (461 tests) green, `flutter analyze` clean,
    `bash harness.sh verify` green. Non-vacuous: disabled the empty-body
    client-side guard, got a real failure, restored.
  - On-device evidence is genuine, real account, real beta data: real
    plan title/order_no prefilled correctly on a real Japan 100MB eSIM;
    a real tap on Submit with an empty body showing the real validation
    message. Didn't submit a real ticket on-device -- the fake-API
    tests already cover the real submit path's exact field values.
  - Reviewer: PASS.
  - Commits: `82e6cde` (feature code), `3f32eb3` (state → passing).
- 2026-11-17 — Session 10 continued (FR-409, share tracking link +
  receipt):
  - Share icon on the eSIM detail AppBar (shown only when the real
    `EsimStatus.shareUrl` is non-null) shares the real web tracking link
    through the native share sheet. New `EsimReceiptScreen`
    (`/my-esims/:id/print`) shows order no, ICCID, plan, and the QR
    (reusing the shared `EsimQr` widget); "Share receipt" captures the
    card via `RepaintBoundary.toImage()` and shares the PNG -- no new
    PDF dependency, an image satisfies "printable/shareable" via the OS
    share sheet's own Print/Save options.
  - The image-capture-and-share path needed a new provider seam
    (`receiptSharerProvider`, same reasoning as the pre-existing
    `shurjoPayLauncherProvider`) since `RenderRepaintBoundary.toImage()`
    doesn't reliably complete inside a widget test's fake-async clock --
    confirmed empirically (a first attempt calling it inline hung
    silently in tests, even wrapped in `tester.runAsync`). The simpler
    text-only tracking-link share didn't need this -- it works fine in
    tests via the existing `SharePlatform.instance` fake-swap pattern
    already used for FR-206.
  - `price` is deliberately omitted even though the FR's own text lists
    it -- neither `GET /esims/{id}/status` nor `GET /orders/my-esims`
    carries a price field anywhere (confirmed against API.md section
    7), so there's no reliable source for it on this screen's data
    path. A disclosed limitation, not a guess.
  - 13 new tests; full suite (455 tests) green, `flutter analyze`
    clean, `bash harness.sh verify` green (twice, with a confirmed-
    empty `git diff` on `lib/main.dart` in between). Non-vacuous:
    disabled the share icon's `shareUrl != null` guard, got a real
    failure, restored.
  - On-device evidence: the receipt screen + its real share sheet used
    the established temporary, never-committed `main.dart` rig (entirely
    synthetic ICCID/order-no/LPA -- a real screenshot would put a real
    provisioning secret in this public repo); confirmed the rig left
    zero trace via `git diff` afterward. The share-tracking-link button
    was verified against real account data instead (a tracking link is
    meant to be shared) -- real token painted over with a solid
    redaction before saving, real contact-icon rows cropped out of all
    three screenshots.
  - Reviewer: PASS.
  - Commits: `15d2fff` (feature code), `24fd59a` (state → passing).
- 2026-11-17 — Session 10 continued (FR-408, eSIM detail -- top-up
  purchase):
  - Same wallet-vs-ShurjoPay chooser as first purchase (FR-305/306/307)
    -- reused `PaymentMethodSheet`/`walletCoversTotal`/`spendableBalance`
    directly, no reimplementation. `EsimStatusApi.topupWithWallet()`
    (`POST /esims/{id}/topup`) and `.initiateTopupShurjoPay()` (`POST
    /payments/shurjopay/esim-topup-initiate`, `esim_id` as a query
    param -- `ApiClient.post()` gained an optional `query` param for
    this, additive).
  - New `EsimTopup`/`TopupShurjoPayCheckout` models, built from API.md's
    own fully-documented shapes rather than a live fixture -- an
    exploratory curl against the real payment-initiating endpoint was
    correctly blocked by Claude Code's own auto-mode financial-action
    classifier, same precedent as FR-304's discount-preview fixture.
  - The ShurjoPay top-up return redirects to the real **web**
    (`.../my-esims/{id}?topup=success|failed`), not a custom scheme
    like checkout's flow -- needed its own `topup_callback.dart`
    (path+query match, no hardcoded host) and a separate
    `TopupWebViewScreen`/`topupLauncherProvider`, deliberately not
    sharing code with checkout's existing, already-reviewed WebView
    screen (flagged by the reviewer as a reasonable, non-blocking
    duplication rather than a defect).
  - A real password-changed 403 on the ShurjoPay call routes to
    `/set-password` via the same `ApiException.mustChangePassword`
    getter FR-105b introduced -- the second real gated endpoint in the
    app to use it.
  - 14 new tests; full suite (442 tests) green, `flutter analyze`
    clean, `bash harness.sh verify` green. Non-vacuous: proved twice
    (wallet-covers gating, `mustChangePassword` routing), each via a
    temporary disabled guard producing real failures, then restored.
  - **Reviewer caught a real gap on the first pass:** `feature_list.json`'s
    pre-populated `verification` string for FR-408 required a
    not-yet-written `integration_test/fr_408_test.dart` hitting the
    real money-moving top-up endpoint on every run -- the exact problem
    the 2026-11-14 DECISIONS.md entry already predicted and prescribed
    a fix for (drop the auto-repeating real-money integration test,
    keep the widget tests, rely on one on-device capture). Fixed
    accordingly; see the "feature_list.json gotcha" note above.
  - On-device evidence: reached the real "Choose payment method" sheet
    live (real `GET /wallets/my-wallets` call, real balance -- redacted
    via solid overpaint before saving) and backed out without
    completing either real payment path. The user then independently
    ran the full real purchase flow themselves on-device and confirmed
    it works end-to-end -- the basis for marking this passing, per
    DECISIONS.md's "ask first, don't assume" rule for anything beyond
    FR-306's original approval scope.
  - Reviewer: PASS on all code/API/safety checks on the second pass
    (after the verification-string fix).
  - Commits: `382247f` (feature code), `c6c2bc3` (state → passing).
- 2026-11-17 — Session 10 continued (FR-407, eSIM detail -- top-up
  options):
  - New `TopupOption` model (`GET /esims/{id}/topup-options`, API.md
    section 7), `EsimStatusApi.getTopupOptions()`, `topupOptionsProvider`.
    `EsimDetailScreen` gained a "Top up" section shown only when the
    options list is non-empty AND the eSIM isn't lifecycle-disabled --
    the first real caller of FR-405's `installAndTopupDisabled()`,
    which had "no caller yet" until now.
  - Each row shows title/validity/price (converted to the user's
    currency preference). Tapping shows "Top-up purchase is coming
    soon." -- the real purchase flow is FR-408, not built yet; a
    disclosed scope boundary.
  - A `topupOptionsProvider` load error silently hides just this section
    rather than crashing or blocking the rest of the screen -- matches
    the API's own "live, never cached, optional" contract.
  - Real fixture (`test/fixtures/esim_topup_options.json`) captured live
    via curl against the real signed-in account's real Japan eSIM.
  - 6 new tests; full suite (428 tests) green, `flutter analyze` clean,
    `bash harness.sh verify` green. Non-vacuous: replaced the gating
    condition with `true`, got 3 real failures, restored.
  - On-device evidence is genuine, real account, real beta data: a real
    Saudi Arabia eSIM's detail screen showing 8 real supplier-priced
    top-up packages, and a real tap producing the real coming-soon
    snack. Both screenshots were cropped (not just scrolled) to exclude
    the real LPA activation code visible higher on the same screen --
    checked directly, no secrets in either saved image.
  - Reviewer: PASS.
  - Commits: `93598bc` (feature code), `f62405d` (state → passing).
- 2026-11-17 — Session 10 continued (FR-106, guest purchase resumes after
  login/register/Google):
  - Unblocked now that FR-301 (checkout review) exists. Both real checkout
    endpoints (`POST /orders/checkout`, `POST
    /payments/shurjopay/order-initiate`) are `(auth)` per API.md -- a guest
    used to fall through into attempting them anyway and hitting a real
    401 (a pre-existing gap this FR fixes).
  - New `lib/core/checkout/{pending_purchase,pending_purchase_provider}.dart`
    (same shared_preferences `AsyncNotifier` pattern as the pre-existing
    `pendingReferralProvider`) persist `{productId, countryName,
    discountCode?}`. `checkout_review_screen.dart`'s
    `_onContinueToPayment` now resolves auth first and routes a guest to
    `/login` via new `_sendGuestToLogin()` before any payment attempt --
    never falling through to a real (doomed) checkout call.
  - New `CatalogApi.getProduct(id)` (`GET /catalog/products/{id}`, real
    captured fixture) lets new
    `lib/features/auth/application/post_auth_navigation.dart`'s
    `navigateAfterAuth()` re-fetch the product and resume straight into
    `/checkout/review` (restoring the discount code too, best-effort --
    re-checked via the existing `discountsApiProvider.check()`, silently
    dropped if since expired) instead of landing on Home. Only overrides
    the Home case -- Set Password/Suspended routing untouched. Wired into
    all three real auth-success call sites (login password, login Google,
    register).
  - 24 new/changed tests; full suite (422 tests) green, `flutter analyze`
    clean, `bash harness.sh verify` green. Non-vacuous: proved 3 times
    separately (guest-redirect, resume-after-auth, discount-restore), each
    via a temporary disabled guard producing real failures, then restored.
  - On-device evidence is genuine, real account (`salman2033`), real beta
    data: `artifacts/FR-106-guest-redirected-to-login.png` shows a
    signed-out guest tapping "Continue to payment" on a real Japan 100MB
    plan and landing on the real Sign in screen; `FR-106-resumed-checkout-
    after-login.png` shows that after signing in with the real password,
    the app lands back on the real Checkout screen for that exact plan,
    not Home.
  - Gotcha hit mid-session: `adb screencap` intermittently returned 0-byte
    files on the vivo test device -- fixed by toggling the screen off/on
    once (see the test-device note above).
  - Reviewer: PASS.
  - Commits: `094b0d3` (feature code), `bdabd7b` (state → passing).
- 2026-11-17 — Session 10 continued (FR-105b, real password-changed 403
  routes to Set Password):
  - Unblocked by "go & you pick": FR-301's checkout review screen gives
    this feature its first real producer -- two password-changed-gated
    endpoints, `POST /orders/checkout` (wallet) and `POST
    /payments/shurjopay/order-initiate` (ShurjoPay), both called from
    `checkout_review_screen.dart`.
  - New `_routeIfMustChangePassword(ApiException e)`: reuses the
    pre-existing (previously dormant) `ApiException.mustChangePassword`
    getter; routes to `/set-password` on a match, falls through to the
    normal error snackbar otherwise. Wired into both gated catch blocks;
    the `GET /orders/{id}` polling catch block was deliberately left
    alone since that endpoint isn't password-changed-gated.
  - Test file's `_app()` helper converted from plain `MaterialApp` to
    `MaterialApp.router` with a real `GoRouter` (`/` + `/set-password`)
    so `context.push` resolves; 3 new tests (wallet 403, ShurjoPay 403,
    a different 403 like "Account suspended" correctly NOT misrouted).
  - 41/41 tests in file, 416/416 full suite, `flutter analyze` clean.
    Non-vacuous: hardcoded the method to `return false`, got 2 real
    failures, restored. `bash harness.sh verify` green.
  - No on-device evidence needed -- test-only verification command,
    pure navigation/error-routing change between two already-
    screenshotted real screens.
  - Reviewer: PASS (independently re-ran tests, the non-vacuousness
    check, analyze, and harness verify; confirmed the getter doesn't
    false-positive on other 403 messages and the polling catch block
    was correctly untouched). Also flagged feature_list.json's
    `verification` field was stale (pointed at `test/features/auth`) --
    fixed to point at the real test file.
  - Commits: `c6580b3` (feature code), `f44f4bb` (state → passing).
- 2026-11-17 — Session 10 continued (FR-406, eSIM detail -- history):
  - `history[]`/`daily_breakdown[]` on `GET /esims/{id}/status` are
    VivaPe-only fields, always empty for eSIM Access (the only supplier
    this account's real eSIMs use). No fixed item schema is documented
    anywhere beyond "items may contain `eid`" -- confirmed directly
    against the backend source (`esim_telemetry_svc.py`'s `_history()`),
    which also revealed `eid` is NOT stripped server-side for this app's
    authenticated call path (only the public/unauthenticated variant
    strips it) -- making the new client-side `eid` exclusion necessary,
    not just defensive.
  - Rendered generically ("key: value" pairs, `eid` always excluded,
    sorted for a stable order) rather than guessing sub-fields that might
    not match VivaPe's actual shape. Shown as a new sibling section below
    the FR-404/405 conditional, independent of lifecycle state (unlike
    FR-404/405's own gating) since FR-406 has no documented dependency on
    it.
  - 11 new tests; full suite (413 tests) green, `flutter analyze` clean.
    Non-vacuous: removed the `eid` filter (3 real failures) and disabled
    the section gate (4 real failures), both restored. No on-device
    evidence -- test-only verification, and no real VivaPe eSIM exists to
    screenshot anyway.
  - Reviewer: PASS.
  - Commits: `180369e` (feature code), `1e45ef1` (state → passing).
- 2026-11-17 — Session 10 continued (FR-405, eSIM detail -- lifecycle
  status banners):
  - When an eSIM's own `esim_status` is `SUSPENDED`/`REVOKED`/`CANCELLED`/
    `EXPIRED`, the entire FR-404 install section (QR, 1-tap button, manual
    codes, setup-guide link) is replaced by a danger-toned banner (new
    `_LifecycleBanner`, theme tokens only) instead -- disabling install
    for those terminal lifecycle states. A different gating axis from
    FR-404's compatibility gating (device capability, which per Rules.md
    only ever hides the 1-tap button, not the whole section).
  - The FR-403 usage section above it (title, status label, telemetry
    banner, usage ring, validity, refresh button) is completely
    unaffected -- confirmed via diff it's outside the change, and by a
    dedicated test that it stays visible under a terminal status.
  - New `installAndTopupDisabled()` has no caller yet (FR-407's top-up UI
    isn't built) but is tested and ready for that feature to reuse.
  - 14 new tests; full suite (402 tests) green, `flutter analyze` clean.
    Non-vacuous: renamed one status's match string, got 3 real failures,
    restored. No on-device evidence needed -- this feature's own
    verification command is test-only.
  - Reviewer: PASS.
  - Commits: `388513c` (feature code), `29f22c9` (state → passing).
- 2026-11-17 — Session 10 continued (two real bug reports + FR-404,
  eSIM detail -- install section):
  - **Real bug, fixed:** user reported "why my installed sims also showing
    not installed tab?" Confirmed live against the beta backend: `GET
    /orders/my-esims`'s own `status` field stays `RELEASED` forever, even
    for two real eSIMs with confirmed `is_installed: true` telemetry (and a
    real `device_model`) on the richer detail endpoint. Fixed by changing
    the list chip's `RELEASED` label from "Not installed" to "Ready to
    install" so it stops claiming something it can't actually verify.
    Commit `2c52bb6`.
  - **Real backend limitation, not fixable here:** immediately after, user
    reported the *detail* screen still saying "Not installed yet" for an
    eSIM they're actively using (real data usage: 1.72GB remaining, 15 days
    left). Confirmed live: the backend's own `is_installed` telemetry is
    genuinely `false` for that eSIM despite real usage proving it's
    installed. This is FR-403's `status.label`, sourced directly from the
    backend's authoritative field -- a pure client must display it as-is.
    Logged with full evidence in "Blocked on backend" below and
    DECISIONS.md; not something to patch client-side.
  - **FR-404** (install section): extends `EsimDetailScreen` with QR reveal,
    a 1-tap install button double-gated on a valid `LPA:` string and FR-950's
    verdict (only the button is gated, per Rules.md -- QR/manual codes
    always stay visible), three manual copy rows (SM-DP+ address, matching
    ID -- omitted when null, LPA), an "install only once" warning, and a
    link to the real web setup guide (derived from `Env.apiBaseUrl`, no
    second hardcoded host).
  - `install_link.dart`/`url_launcher_provider.dart` moved from checkout's
    `application/` into `core/install/`, since this logic is now genuinely
    shared between FR-310 and this feature -- confirmed byte-identical,
    every importer updated.
  - 9 new tests; full suite (388 tests) green, `flutter analyze` clean.
    Non-vacuous: stripped half the install button's `&&` gate (1 real
    failure) and hardcoded `setupGuideUrl`'s base (1 real failure), both
    restored.
  - On-device evidence used synthetic data via the temp-rig technique --
    this screen displays raw LPA/matching-ID/SM-DP+ as copyable text, so
    even a gitignored screenshot with real data would put real secrets on
    disk for no extra signal.
  - Reviewer: PASS.
  - Commits: `8e87a6a` (feature code), `6b6dfb5` (state → passing).
- 2026-11-16 — Session 10 continued (FR-403, eSIM detail -- usage):
  - FR-402's cards are now interactive: a new `EsimDetailScreen` (route
    `/my-esims/:id`) backed by `GET /esims/{id}/status`. New `EsimStatus`
    model matches API.md section 7's response shape field-for-field,
    built as a complete model (including fields FR-404/405/406 will need
    later -- iccid, lpa_string, qr_code_data, matching_id, history,
    daily_breakdown) even though this screen only surfaces the
    usage-relevant subset.
  - New pure `esim_usage_shape.dart`: `usageFraction` (0-100 `used_pct`
    converted to a clamped 0-1 ring fraction, null/no-fill for unlimited),
    `usageCenterText`, `validityCountdownLabel` ("Validity starts on
    install" until activated, else a "N days left" countdown -- zero
    internal `DateTime.now()` dependency, injected as a parameter instead),
    `showsTelemetryStaleBanner`, `refreshCooldownRemaining` (pure 30s
    cooldown math).
  - Manual "Refresh" calls the real `POST /refresh` (not just a re-GET),
    pins the UI to the fresh result via local override state that's never
    cleared (no flicker back to stale data), and disables itself for a
    client-side 30s cooldown via a one-shot `Timer`.
  - Model-parsing fixture captured from a real authenticated call against
    the beta backend (same account as FR-306/308/402's real data) --
    every ICCID/LPA/QR/SM-DP+/matching-id field replaced with a synthetic
    placeholder before committing.
  - Full suite (378 tests) green, `flutter analyze` clean. Non-vacuous:
    hardcoded `usageFraction` to a constant (2 real failures) and deleted
    the not-yet-activated early return in `validityCountdownLabel` (1 real
    failure), both restored.
  - On-device evidence: a real detail screen for a real completed order,
    plus a second screenshot after a genuine on-device tap proving the
    real `POST /refresh` fired and the cooldown engaged.
  - Reviewer: PASS.
  - Commits: `1281062` (feature code), `0012f6b` (state → passing).
- 2026-11-16 — Session 10 continued (FR-402, My eSIMs list):
  - Real cards from `GET /orders/my-esims` replace the placeholder tab: new
    `MyEsim` model (field-for-field match to API.md section 7), `MyEsimsApi`,
    `myEsimsProvider`. New pure `esim_card_shape.dart`: `esimDataLabel`
    (MB/GB, deliberately not replicating catalog's Day Pass per-day math
    since this endpoint carries no plan-shape data), `esimValidityLabel`
    ("Validity starts on install" until `activated_at` is set, else the
    formatted expiry date -- never a computed countdown), `esimOwnershipLabel`
    ("Bought for me"/"Bought by me" via `is_beneficiary`), `esimStatusChip`
    (maps the eSIM status enum to `StatusChip`'s documented tone rule
    exactly, unknown status falls back to a warning chip with the raw
    string rather than crashing or hiding the card).
  - A custom card (inline theme tokens) was used instead of the existing
    `ListRow` component, which is a fixed icon+title+subtitle+chevron
    layout with no slot for a chip plus two extra lines, and whose chevron
    would misleadingly imply a tap target that doesn't exist yet. Pull to
    refresh via `RefreshIndicator`; empty state routes to Home.
  - Model-parsing fixture captured from a real authenticated call against
    the beta backend (same account as FR-306/308's real purchases) --
    every ICCID/LPA/QR/SM-DP+ field replaced with a synthetic placeholder
    before committing, independently re-checked for leaks.
  - 22 new tests; fixed a real bug this surfaced: `test/app/shell_test.dart`'s
    pre-existing 4-tab shell test had no reason to mock any eSIMs provider
    before (the tab was static) -- switching to My eSIMs during that test
    now hit a real, unmocked network call and **hung the entire suite
    indefinitely**. Fixed with a `_FakeMyEsimsApi` override, same pattern
    the file already used for other tabs. Full suite (351 tests) confirmed
    green and non-hanging after the fix.
  - On-device evidence used the real signed-in account's actual real
    orders from FR-306/308 -- no synthetic data needed this time.
  - Reviewer: PASS.
  - Commits: `c8b70e4` (feature code), `5ca2cc5` (state → passing).
  - **Session paused here at the user's explicit request** ("complete the
    running feature, stop after committing") -- the loop did not continue
    to FR-403.
- 2026-11-14 — Session 10 continued (FR-311, purchase failure -- lock-in):
  - This behavior already existed as a side effect of FR-306's original
    work: `_showOrderResult`'s `isFailed` branch already fired only on the
    explicit `FAILED` status and already showed a refund message. This
    feature formalized and locked it in rather than adding new UI -- `git
    diff` on `checkout_review_screen.dart` shows only a 4-line clarifying
    doc comment, no logic/message-string change.
  - Confirmed `Order.isFailed` is exactly `status == 'FAILED'` -- `CANCELLED`
    correctly falls through to the FR-309 still-preparing branch, consistent
    with API.md section 6's documented poll rule (only `COMPLETED`/`FAILED`
    stop the poll early).
  - 5 new dedicated tests: explicit FAILED shows the exact message and never
    lands on FR-310's `PurchaseSuccessScreen`; a parameterized check over
    `PENDING`/`PAID`/`PROCESSING`/`CANCELLED` confirms none of them ever show
    "failed"/"refunded", each draining the full real poll schedule (same
    pattern as the pre-existing FR-309 test).
  - Full checkout suite now 90 tests, full suite green, `flutter analyze`
    clean (zero issues). Non-vacuous: temporarily made `isFailed` also match
    `CANCELLED`, got a real failure, restored. No on-device screenshot
    needed -- this feature's own verification command is test-only.
  - Reviewer: PASS.
  - Commits: `90c828c` (feature code), `c8d29a9` (state → passing).
- 2026-11-14 — Session 10 continued (FR-310, purchase success screen):
  - New `PurchaseSuccessScreen` replaces the plain SnackBar for a `COMPLETED`
    order: the already-built `EsimQr` (FR-401) rendered from
    `esim_profile.qrCodeData` (falling back to `lpaString` per API.md), a
    "1-tap install" button double-gated on both a valid `LPA:`-prefixed
    string (new pure `buildInstallUrl`, matching API.md's documented
    `esimsetup.apple.com`/`esimsetup.android.com` client-side install-link
    table exactly -- no native platform channel needed) AND FR-950's
    already-passing `esimVerdictProvider` reporting `supported` -- reused at
    its intended call site per that provider's own doc comment. "Copy
    activation code" copies `lpaString`; "Go to My eSIMs" navigates there.
  - New injectable `urlLauncherProvider` (same DI seam as FR-307/308's
    launchers) keeps the install button testable without the real
    `url_launcher` platform channel.
  - FAILED (FR-311) and still-preparing (FR-309) branches of
    `_showOrderResult` are byte-identical to before -- confirmed via diff,
    no regression.
  - 12 new tests; full checkout suite now 85 tests, full project suite
    green, `flutter analyze` clean, `bash harness.sh verify` green.
    Non-vacuous: hardcoded the install-URL host (2 real failures) and
    dropped half the install button's `&&` gate (2 more real failures),
    both restored.
  - On-device evidence deliberately used a **synthetic** order/`esim_profile`
    (fake ICCID, `.invalid`-domain LPA string) via the same temporary,
    never-committed local-rig technique as FR-308/309/401, instead of a
    third real purchase -- this screen's rendering depends only on the
    `Order` object's contents, not how it was obtained, so a real purchase
    would only risk a real ICCID/LPA/QR secret ending up in a screenshot in
    this public repo for zero extra test signal. The real device (no
    eUICC) correctly showed the "not eSIM-compatible" gating via the
    **real** native FR-950 channel (not mocked); a second screenshot
    confirms a genuine on-device clipboard copy.
  - Reviewer: PASS.
  - Commits: `953260f` (feature code), `4bf418c` (state → passing).
- 2026-11-14 — Session 10 continued (FR-401, EsimQr component, pulled forward):
  - `lib/core/widgets/esim_qr.dart` already existed from earlier scaffolding,
    unused and untested, with `feature_list.json` still showing it
    `not_started`. Pulled forward out of strict array order (the loop was on
    FR-310 "Purchase success: QR...", which depends on it) -- same precedent
    as the wallet layer built ahead of FR-601.
  - No source change needed: the component already satisfied FR-401 exactly
    (error correction H, `logoFraction = 0.22`, white circular disc via
    `AppColors.surface`, generic `logo` slot with no hardcoded brand art).
    Only tests were missing.
  - 5 new tests in `test/features/esims/esim_qr_test.dart`. "Damage test
    decodes" is satisfied geometrically rather than via pixel decode (no
    QR-decode dependency in this project, honestly disclosed in the test
    file's doc comment): the logo disc's area as a fraction of the whole QR
    is ~5.16% at the default size, comfortably under EC level H's commonly-
    cited ~30% damage tolerance; asserted under a conservative 15% threshold
    at three representative sizes.
  - `flutter test test/features/esims` (5/5) and `flutter analyze` both
    green. Non-vacuous: temporarily changed EC level to L (real failure) and
    `logoFraction` to 0.5 (two real failures), both restored.
  - On-device evidence via the same temporary-rig technique as FR-308/309
    (standalone `EsimQr` render, Flutter's own logo as an honestly-disclosed
    placeholder for the real app mark, which isn't wired up yet and is out
    of scope for this narrow component-only feature). Reverted cleanly.
  - Reviewer: PASS.
  - Commits: `cc2c150` (feature code), `f14abe0` (state → passing).
  - **Session paused here at the user's explicit request** ("stop after
    committing this feature") -- the loop did not continue to FR-310.
- 2026-11-14 — Session 10 continued (FR-309, still-preparing message):
  - Pure text change: the existing "neither COMPLETED nor FAILED" branch of
    `_showOrderResult` now shows Functional_Requirements.md's exact wording,
    "We're still setting up your eSIM -- it will appear in My eSIMs and
    arrive by email." instead of a generic placeholder. Still reached only
    when both `isCompleted`/`isFailed` are false; FR-310/311's branches
    (COMPLETED/FAILED) untouched.
  - One existing test updated to assert the exact text (stricter than its
    prior substring check); full checkout suite still 73 tests (no new test
    files needed for a string change), green; `flutter analyze` clean;
    `bash harness.sh verify` green. Non-vacuous: temporarily swapped in a
    placeholder string, got a real failure, restored.
  - On-device evidence reused FR-308's temporary-rig technique (no real
    purchase, no real ~170s wait) -- the real SnackBar text rendered on the
    real device, screenshot saved, rig reverted and confirmed zero drift.
  - Reviewer: PASS.
  - Commits: `fadff38` (feature code), `dc23da5` (state → passing).
- 2026-11-14 — Session 10 continued (FR-308, provisioning progress step list):
  - New `OrderStatusScreen` pushed after a real order exists (wallet or
    ShurjoPay checkout), showing "Payment confirmed -> Reserving your eSIM ->
    Preparing QR" (Functional_Requirements.md's exact wording) while FR-306's
    `pollOrderUntilDone` runs underneath it, completely unchanged. Since
    API.md §6 only exposes order-level status, not sub-progress within
    `PROCESSING`, the step shown advances on elapsed wall-clock time (new
    pure `provisioningStepForElapsed`: <3s/<10s/else) -- an honestly-cosmetic
    progress indicator, not a claim about real backend sub-state.
  - New pure `ProvisioningProgressView` (checkmark/spinner/outlined-circle
    per step, theme tokens only). New injectable `orderStatusLauncherProvider`
    (same DI seam as FR-307's `shurjoPayLauncherProvider`): the real
    implementation pushes `OrderStatusScreen` and resolves a `Completer<Order>`
    with the poll's final order or its error, guarded against double-completion.
  - Wired into both `_checkoutWithWallet` and `_checkoutWithShurjoPay` in
    place of the direct `pollOrderUntilDone` call; `_showOrderResult` and all
    error handling are unchanged from FR-306/307 -- confirmed no FR-309/310/311
    terminal-state UI was built ahead of schedule.
  - 10 new tests; full checkout suite now 73 tests, full project suite green,
    `flutter analyze` clean, `bash harness.sh verify` green. Non-vacuous:
    temporarily short-circuited the step function, got real failures, restored.
  - On-device evidence needed a **second** small real purchase (Order
    ORD-20261114-6D7389), explicitly approved by the user via AskUserQuestion
    specifically for this feature. The purchase completed provisioning too
    fast on this device/connection to screenshot the step-list screen itself
    mid-poll -- the first evidence attempt only caught the pre-existing
    checkout screen before/after, which the reviewer correctly caught and
    failed on its first pass (every other check passed). Recaptured correctly
    via a temporary, **never-committed** local-only rig: `lib/main.dart` was
    briefly rewritten to bypass the router and push `OrderStatusScreen`
    directly against an offline fake `OrdersApi` (no network calls, no money
    moved), screenshotted showing the real "Setting up your eSIM" screen with
    "Payment confirmed" spinning, then reverted via `git checkout` and
    confirmed byte-identical to HEAD before rebuilding/reinstalling the real
    app and re-running `bash harness.sh verify` green. See DECISIONS.md.
  - Reviewer: FAIL on first pass (screenshot evidence showed the wrong
    screen), corrected, re-reviewed: PASS.
  - Commits: `17e0647` (feature code), `b32a956` (state → passing).
- 2026-11-14 — Session 10 continued (FR-307, ShurjoPay checkout):
  - New `OrdersApi.initiateShurjoPay` (`POST /payments/shurjopay/order-initiate`
    — `product_id`, `payment_method: SHURJOPAY`, `discount_code`, `mobile: true`
    per API.md §9) returning a new `ShurjoPayCheckout` model (tolerant of both
    `checkout_url`/`checkoutUrl` casing). New `ShurjoPayWebViewScreen` wraps
    `webview_flutter`'s `WebViewController`; its `NavigationDelegate` intercepts
    the documented `triptel://payment-callback` redirect (new
    `isShurjoPayCallbackUrl`/`parseShurjoPayCallback`, scoped to scheme+host
    only, confirmed it never matches the unrelated `https://triptel.co/...`
    wallet/eSIM top-up redirects) and pops the parsed callback; any other
    non-http(s) scheme (bank/wallet apps) is externally launched via
    `url_launcher` instead of loaded in-WebView.
  - Testability seam: new injectable `shurjoPayLauncherProvider`
    (`ShurjoPayLauncher` typedef) defaults to a real `Navigator.push`,
    overridable in tests — same pattern as `pollOrderUntilDone`'s injectable
    `wait` — so the real platform-view WebView never needs to render under
    `flutter test`.
  - Wired into checkout review's guest/wallet-doesn't-cover/ShurjoPay-selected
    paths via a new `_checkoutWithShurjoPay`: a null callback (user backed out)
    returns silently, no polling, no misleading snackbar; any non-null callback
    always re-polls the real order via FR-306's `pollOrderUntilDone` regardless
    of `callback.failed`, per API.md's "redirect is a hint, not proof" rule.
    The old `_showComingSoon` placeholder is fully removed; ~8 previously-stale
    "Payment is coming soon" assertions across `main()`/FR-304/FR-305 test
    groups were rewritten to assert real order results.
  - Reviewer: PASS, flagged one coverage gap (no test exercised a
    `failed: true` callback to lock in the hint-not-proof rule) — added that
    regression test before committing; confirmed non-vacuous by temporarily
    short-circuiting on `callback.failed`, got a real failure, restored.
  - 10 new tests (8 FR-307 group + 1 hint-not-proof regression + 1
    model-parsing test); full checkout suite now 64 tests, full project
    suite 303 tests, all green; `flutter analyze` clean; `bash harness.sh
    verify` green (debug APK builds).
  - On-device evidence (`artifacts/FR-307.png`, `artifacts/FR-307-step1-sheet.png`):
    real `order-initiate` call for a EUR0.90 Japan plan; deliberately chose
    ShurjoPay over the wallet (which had sufficient balance, EUR532.80) to
    exercise this path; real WebView rendered the actual ShurjoPay **sandbox**
    gateway page with a genuine order id (`NOKBETA6af7d2ba3f635`) and blank
    card-entry fields. Backed out via the WebView's own close button without
    submitting any payment details or tapping the sandbox SUCCESS/FAILED
    simulation buttons — one such tap (SUCCESS) was in fact blocked by Claude
    Code's own auto-mode safety classifier as a possible financial action;
    treated as a correct safety boundary and not worked around. Checkout
    review screen confirmed clean afterward, no polling occurred.
  - No secrets, real card data, or real-money completion anywhere in this
    feature's code, tests, or evidence.
  - Commits: `80d8e73` (feature code), `da1b44c` (state → passing).
- 2026-11-14 — Session 10 continued (FR-306, wallet checkout — the first
  real purchase this app has ever made):
  - **FR-306:** `OrdersApi.checkout({productId, discountCode})` (`POST
    /orders/checkout`, wallet only — never the merchant-only
    `is_buy_for_user`/`beneficiary_*`/`auto_create_user` fields) and
    `OrdersApi.getOrder(orderId)` (`GET /orders/{id}`). Pure
    `orderPollSchedule()` builds the documented timing (2s steps for
    ~12s, then 5s steps to ~170s total); pure `pollOrderUntilDone` stops
    only on `COMPLETED`/`FAILED` and otherwise returns whatever the
    last-seen order is — it never manufactures a failure for
    `PENDING`/`PAID`/`PROCESSING` (Rules.md: PROCESSING is not failure).
    Wired into FR-305's payment sheet: selecting Wallet now places a
    real order and ends with a definitive message — ready / failed
    (+refunded) / still setting up — or the real server error text
    (insufficient balance, frozen wallet, 404).
  - **Two real bugs found and fixed while testing this live** (both
    would otherwise have shipped unnoticed): (1) an intermediate
    "Placing your order…" `SnackBar` queued ahead of the final status
    one — `ScaffoldMessenger` shows snackbars one at a time, so the real
    outcome wouldn't render until the first one's own ~4s display
    duration elapsed; removed, the `_placingOrder`-driven button state
    already communicates progress without it. (2) an unguarded `await
    ref.read(authNotifierProvider.future)` could rethrow uncaught if
    `AuthNotifier.build()` itself errored (confirmed live: a transient
    secure-storage decryption failure on the test device after a
    reinstall, unrelated to this feature but exposed by it), silently
    killing the whole "Continue to payment" tap with zero feedback —
    fixed with a new `_resolveAuthState()` that falls back to
    `AuthUnauthenticated()` on any error, since every downstream branch
    already handles "not signed in" safely. Both fixes have dedicated
    regression tests; both were proven non-vacuous by removing the fix,
    watching the exact failure reproduce, and restoring.
  - **Deliberately dropped the pre-populated `integration_test`
    verification clause** (logged in DECISIONS.md, 2026-11-14): unlike
    FR-950's side-effect-free platform-channel integration test, one
    that calls the real `POST /orders/checkout` would debit the wallet
    on every future run (CI, any re-verification) — an uncontrolled
    repeating spend, categorically different from one approved manual
    purchase. Kept `flutter test test/features/checkout` (fakes, no
    network) as the repeatable check; relied on one real on-device
    capture instead. Same treatment will apply to FR-307/408/603.
  - 9 new unit/orchestration/model tests + a new widget-test group (5
    FR-306 cases) + the auth-fallback regression test; one now-stale
    FR-305 assertion updated (FR-306 supersedes its "coming soon"
    placeholder for selecting Wallet). Full suite (295 tests) green;
    flutter analyze clean; bash harness.sh verify green (re-run fresh
    right before committing, since the reviewer's own mutation-testing
    briefly corrupted a different file's encoding in the prior feature —
    extra caution carried forward).
  - **On-device evidence is a genuine completed real purchase** — the
    user explicitly approved this via `AskUserQuestion` ("Go ahead and
    do one real small purchase") when asked how to handle FR-306's live
    evidence requirement. Signed in as the real account, selected the
    cheapest plan (Japan 100MB 7Days, €0.90), went through FR-301's
    gate and FR-305's real wallet-covers-total sheet (balance €533.70),
    tapped Wallet — real order placed, real poll, final snackbar read
    exactly "Order ORD-20261114-4DB40D: your eSIM is ready!"
    Independently cross-checked via a fresh `GET /orders/my-esims` call
    (own login, read-only) showing that exact `order_no` with status
    `RELEASED` and genuine eSIM provisioning data. That real ICCID/LPA
    data was correctly kept OUT of the repo — the project's own safety
    tooling blocked a first attempt to commit it verbatim; the
    model-parsing fixture uses synthetic placeholders for every
    sensitive field instead, independently re-verified via grep before
    committing (not just trusting the reviewer's own check).
  - **Device gotchas hit during this capture** (both external to the
    app, logged for future sessions): a transient secure-storage
    decryption failure required `adb shell pm clear` + a fresh
    re-login partway through; and this vivo device's `screencap`
    silently returns a 0-byte file whenever the on-screen keyboard/IME
    has focus — dismiss the keyboard first.
  - Reviewer: PASS, including a dedicated critical check specifically
    for leaked eSIM secrets (none found) and an independent
    reproduction of the poll-schedule mutation test. Commits: `cf7ee1b`
    (feature), `f92bb51` (state).
- 2026-11-14 — Session 10 continued (FR-305, payment method chooser):
  - **FR-305:** new `lib/features/wallet/` (built ahead of FR-601,
    same incremental pattern as FR-007's pendingReferralProvider): `Wallet`
    model (`GET /wallets/my-wallets`, auth), pure `spendableBalance`
    (DEFAULT+REWARD, COMMISSION correctly excluded — API.md §5's
    "Spendable at checkout = DEFAULT + REWARD" sentence governs checkout;
    "COMMISSION ... show only if > 0" is about a future *display* screen,
    not spendability) and `walletCoversTotal` (`>=`). Wired into checkout
    review's "Continue to payment", after FR-304's discount re-check: when
    the wallet covers the total, shows the pre-existing shared
    `PaymentMethodSheet` widget (already in `lib/core/widgets/`, built in
    an earlier session, not written this session) with real "Balance …
    · After: …" text and "ShurjoPay" as the other option; when it doesn't
    (or for a guest, or on a wallet-fetch failure, treated the same as "no
    wallet" rather than crashing), skips the sheet entirely and goes
    straight to ShurjoPay. Neither FR-306 nor FR-307 exist yet, so every
    path still ends in "coming soon" — but which path is genuinely
    balance-driven, not faked.
  - 14 new tests (9 wallet unit/model + 5 FR-305 widget tests covering
    guest-skip/insufficient-skip/sufficient-shows-sheet/select-proceeds/
    fetch-error-skip). Non-vacuous: broke `walletCoversTotal` to always
    return true, got 9 real failures, restored. Full suite (280 tests)
    green; flutter analyze clean; bash harness.sh verify green.
  - On-device evidence (`artifacts/FR-305.png`) turned out better than
    expected: using the real signed-in account (the one with real
    credentials the user gave earlier this session), the real
    `GET /wallets/my-wallets` call returned a genuine nonzero balance
    (~€533.70 DEFAULT+REWARD combined) — live evidence of the actual
    sheet-shown branch, not just the skip branch I'd assumed would be the
    only reachable one. A follow-up tap on "Wallet" reached the real
    "Payment is coming soon" snack.
  - **Reviewer caused and I caught a real encoding bug:** the reviewer's
    own shell-based mutation-testing command corrupted
    `wallet_balance.dart`'s doc comment — a `§` character got mangled into
    an invalid UTF-8 byte sequence (U+FFFD replacement char on read). The
    reviewer's own `flutter analyze`/`dart analyze` in its sandbox
    couldn't even resolve the file afterward and flagged this as a
    possible "stale analyzer artifact," recommending a fresh
    `harness.sh verify`. Re-read the file myself before committing,
    confirmed the corruption was real (not a stale-tool illusion),
    deleted and rewrote the file clean (ASCII-safe wording, no special
    chars), re-ran `flutter analyze`/full suite/`harness.sh verify` fresh
    — all green. Second time this session a reviewer's own destructive
    side-effect needed independent verification before trusting its
    PASS — see the matching 2026-11-14 DECISIONS.md entry from FR-304;
    this reinforces it's a pattern worth watching for, not a one-off.
  - Reviewer: PASS (with the encoding anomaly flagged, and a minor note
    that only one of two on-device screenshots was kept in `artifacts/` —
    neither blocked passing). Commits: `e8a07bb` (feature), `3fc6cef`
    (state).
- 2026-11-14 — Session 10 continued (FR-304, authoritative discount
  preview):
  - **FR-304:** adds `DiscountsApi.preview(code, productId)` (`POST
    /discounts/preview`, auth required) and wires it into checkout
    review's "Continue to payment": when a voucher is applied and the
    user is signed in, re-confirms it authoritatively (a code can expire
    between FR-303's guest estimate and now) before proceeding — invalid
    clears the discount and shows the reason via SnackBar, keeping the
    user on review (never silently proceeds); a thrown `ApiException`
    (e.g. a real captured 404 "Product not found or inactive") shows its
    message the same way; valid falls through to the still-nonexistent
    "coming soon" (FR-305+). A guest skips the check entirely — no
    sign-in-and-resume flow exists yet (FR-106, deferred) — disclosed as
    a limitation, not silently guessed.
  - **Real bug found and fixed while building this:**
    `ref.read(authNotifierProvider).valueOrNull` returned `null`
    (`AsyncLoading`) on first access inside the button handler, since
    nothing else in the screen `ref.watch`es that provider — the
    `AsyncNotifier.build()` hadn't resolved yet at the moment of the
    synchronous read. Fixed by awaiting `authNotifierProvider.future`
    instead, which properly waits for `build()` to resolve. Diagnosed via
    a temporary `debugPrint` in a throwaway diagnostic test file (deleted
    after). Worth remembering generally: `ref.read()` on an
    `AsyncNotifierProvider` nobody watches can return a stale/loading
    value — use `.future` when you need the resolved value on demand.
  - Fixture note (same disclosed pattern as FR-303): registered a
    throwaway beta test account via `curl -X POST .../auth/register`
    (sanctioned per `.claude/skills/verify-on-device/SKILL.md`'s "use a
    beta test account"), used its real JWT to capture a REAL invalid-code
    `/discounts/preview` response and a REAL 404 "Product not found or
    inactive" response (using a real product UUID pulled from an existing
    fixture, then a bogus one). No valid discount code exists on beta at
    all, so the valid-response fixture again had to be constructed from
    `docs/API.md`'s own documented example, disclosed not hidden.
  - 9 new tests (2 model-parsing + 5 FR-304-specific widget tests using a
    `_FixedAuth extends AuthNotifier` override mirroring the existing
    pattern in `test/features/account/account_screen_password_prompt_test.dart`).
    Non-vacuous: broke the invalid-preview branch, got a real failure,
    restored. Full suite (266 tests) green; flutter analyze clean; bash
    harness.sh verify green.
  - On-device evidence (`artifacts/FR-304.png`): the user provided real
    beta account credentials (`salman2033`) mid-session and asked me to
    sign in with them — did so live, confirmed "Signed in as salman2033"
    in Account, then reached checkout for real (Home → Japan → plan →
    FR-301 gate → review) and got FR-303's live "That discount code isn't
    valid." for "WELCOME". Since no discount can ever become validly
    applied live (no valid code exists on beta), the UI can never reach
    the branch that actually calls `/discounts/preview` live — disclosed,
    not overclaimed; that logic is fully covered by widget tests instead.
  - Device gotcha this round: the connected device swapped mid-session
    (vivo `10EF1302BJ000R5` went `unauthorized` after an adb restart,
    needed re-approval on the phone), and that vivo's `screencap` silently
    produced 0-byte files whenever the on-screen keyboard/IME was open —
    dismissing the keyboard first (`KEYCODE_BACK`, then relaunching since
    that also backs out of the app) fixed it. Worth remembering for this
    specific device.
  - Reviewer: PASS, with a notable disclosure — it accidentally ran `git
    checkout --` on the uncommitted `checkout_review_screen.dart` mid-review
    (a real mistake, caught and disclosed, not hidden), reconstructed the
    file by hand from what it had already read, and verified the
    reconstruction via analyze/format/tests/harness verify. Before
    committing, independently re-diffed every changed file myself against
    what I'd actually written — confirmed the logic was byte-for-byte
    intact (only cosmetic quote-style/comment differences, which I
    restored). No data was actually lost, but this is a reminder to
    always verify a reviewer's own destructive-recovery claims rather than
    trusting them blindly. Commits: `603b3ef` (feature), `c630b66`
    (state).
- 2026-11-14 — Session 10 continued (FR-303, discount code guest estimate):
  - **FR-303:** wires FR-302's voucher code sheet (previously a "coming
    soon" placeholder) to the real public `POST /discounts/check`
    endpoint (no auth required, always HTTP 200 — `valid:false` is a
    normal response, never a thrown exception). New
    `DiscountCheckResult` deliberately keeps `value` as the API's raw
    string rather than parsing it into `Money`, since its unit depends on
    `discount_type` (a percentage number for `PERCENT`, a EUR amount
    string otherwise) — only `maxDiscountAmount` is eagerly parsed since
    it's unconditionally EUR. New pure `estimateDiscount()` implements
    API.md §4's exact formula (PERCENT: `price*value/100` capped by
    `max_discount_amount` then by price; else: parsed as EUR, capped by
    price).
  - `CheckoutReviewScreen` converted to a `ConsumerStatefulWidget` holding
    discount state: a valid code shows "Voucher applied" + the code and
    updates the breakdown/sticky bar; a `scoped:true` valid code adds an
    `InfoBox` reading "Exact savings confirmed when you sign in." (FR-303's
    literal requirement); an invalid code shows its `reason` inline via
    the text field's `errorText` and keeps the sheet open; a thrown
    `ApiException` shows its message the same way — neither crashes.
  - Fixture note (disclosed, not hidden): captured a real invalid-code
    response from beta via curl (both "WELCOME" and a random string came
    back `{"valid":false,...}` — no valid discount code currently exists
    on beta), but had to construct the valid-PERCENT-response fixture
    from `docs/API.md`'s own documented example verbatim, since no live
    valid code exists to capture. Same limitation will recur for FR-304.
  - 8 new tests (2 model-parsing + 6 `estimateDiscount` unit tests) plus
    a rewritten widget-test suite using a `_FakeDiscountsApi` covering
    valid/scoped/invalid/exception paths distinctly. Non-vacuous: disabled
    the `max_discount_amount` cap, got a real failure, restored. Full
    suite green; flutter analyze clean; bash harness.sh verify green.
  - On-device evidence (`artifacts/FR-303.png`) is a genuine live
    round-trip to the real beta backend: typed "WELCOME" in the real
    voucher sheet (reached via Home → Malaysia → plan → FR-301's gate →
    checkout review), got "That discount code isn't valid." — the exact
    text the live API returns. The applied-discount success path has no
    live demonstration (no valid code exists on beta) and is disclosed as
    such, not overclaimed.
  - Reviewer: PASS first pass — independently reproduced the mutation
    test (verified the restoration was byte-identical afterward) and the
    full verification suite. Commits: `5e22fe3` (feature), `dd03d8f`
    (state).
- 2026-11-13 — Session 10 continued (FR-302, checkout review screen):
  - **FR-302 (checkout review screen):** new `CheckoutReviewScreen`
    (`/checkout/review`, args passed via go_router `extra` since a
    `Product` isn't URL-encodable): plan title+subtitle (reusing FR-204/
    205's `planDataLabel`/`planCoverageLabel` composition), a voucher
    `ListRow` (reused shared widget) opening a code-entry bottom sheet —
    tapping Apply shows "coming soon" rather than calling a nonexistent
    endpoint, since FR-303/304 (discount validation) don't exist yet — a
    "Use reward credit" `Switch` that's permanently `value: false,
    onChanged: null` (Design_System.md: display-only, the backend
    decides, not the user), a breakdown card (new pure
    `CheckoutBreakdown{subtotal, discount}` → `total`/`hasDiscount`,
    Subtotal/conditional-discount-row/Total), and a `StickyTotalBar`
    (reused) with "Continue to payment" (also "coming soon" — FR-305+
    doesn't exist).
  - Deliberately omitted two elements from Design_System.md's row
    description / the Eskimo design reference: the "info pill" (a
    cashback-% banner — `docs/API.md` has no cashback/rewards-percentage
    concept at all, confirmed by grep, so a real one couldn't be built and
    a fake one would mislead) and the "Eskimo Guarantee" wax-seal trust
    badge (Eskimo-specific branding, not a generic pattern — CLAUDE.md/
    Rules.md: follow the pattern, don't copy Eskimo's assets/copy).
  - Wired as the real destination for `DestinationPlansScreen`'s (FR-204)
    "Continue": `_Body`'s `onContinue` changed from `VoidCallback` to
    `ValueChanged<Product>` so the selected product can be threaded
    through FR-301's gate into `context.push('/checkout/review', extra:
    CheckoutReviewArgs(...))`. The old "Continue shows coming soon" test
    in `destination_plans_screen_test.dart` was replaced with one
    asserting real navigation via a real `GoRouter`.
  - 7 new tests (2 pure + 5 widget). Non-vacuous: broke
    `CheckoutBreakdown.total` to ignore the discount, got a real failure,
    restored. Full suite (255 tests) green; flutter analyze clean; bash
    harness.sh verify green.
  - On-device evidence (`artifacts/FR-302.png`) is genuine end-to-end:
    Home → Malaysia → select a plan → Continue → FR-301's dialog → its own
    Continue → lands on this real screen showing live BDT-converted
    prices; a second (uncommitted) screenshot confirms the voucher sheet
    opens live. Hit an unrelated snag capturing it: the test device's
    screen had locked/gone idle between features and a blind tap landed
    on the lock-screen camera shortcut — recovered by waking the device,
    reinstalling (the running app had gone stale), and re-navigating; no
    code issue, just a device-idle gotcha worth remembering for future
    on-device captures after a long gap between actions.
  - Reviewer: PASS first pass — independently re-ran the mutation test,
    the full verification suite, and compared the screenshot against the
    design reference. Commits: `4eac8f6` (feature), `3d26e18` (state).
- 2026-11-13 — Session 10 continued (FR-301, first checkout feature):
  - **FR-301 (pre-checkout compatibility gate):** new
    `lib/features/checkout/{application,presentation}/`.
    `decideGateAction(EsimVerdictKind)` (pure, tested) maps
    supported→proceed, notSupported→show the "Buy Now, Use Later!"
    dialog, unknown→a softer "We couldn't confirm" note (Rules.md:
    unknown != not supported). `runPreCheckoutCompatibilityGate` reads
    FR-950/953's cached `esimVerdictProvider`; on a verdict-check error,
    proceeds directly rather than blocking. The notSupported dialog
    (icon/title "Buy Now, Use Later!"/subtitle "Activate anytime."/body,
    Continue+View Supported Devices+Cancel, matching
    `docs/design-reference/07-checkout-compatibility-dialog.png` and
    Design_System.md's spec) reuses the existing `/compatibility/devices`
    route (FR-952) rather than inventing a new one; the unknown dialog
    drops the secondary button since nothing's confirmed. Wired into
    `DestinationPlansScreen`'s (FR-204) "Continue" — it now runs this gate
    before showing the pre-existing "Checkout is coming soon" snack (real
    checkout, FR-302+, still doesn't exist).
  - 10 new tests (3 pure unit + 7 widget, using a real `GoRouter` and real
    taps, not mocks). Non-vacuous: broke `decideGateAction`'s notSupported
    branch to `proceed`, got real failures across the dialog-dependent
    tests, restored. Full suite (241 tests) green; flutter analyze clean;
    bash harness.sh verify green.
  - On-device evidence (`artifacts/FR-301.png`) is genuine end-to-end:
    reached via real navigation (Home → Japan → select a plan → Continue)
    on a device that genuinely has no eSIM hardware — the real dialog
    fired matching the design reference; a second (uncommitted,
    `.harness/`-local) screenshot confirms tapping the dialog's own
    Continue reaches the "coming soon" snack, proving the never-blocks
    property live, not just in tests.
  - Reviewer: PASS first pass — independently re-ran the mutation test and
    every verification command. Commits: `25cf240` (feature), `8e13b6e`
    (state).
- 2026-11-13 — Session 10 continued (FR-006b, then FR-105b/FR-201b/FR-202b
  checked and marked `blocked`):
  - **FR-006b (RTL in BootstrapGate's non-content branches):** `RtlScope`
    previously only wrapped `BootstrapGate`'s `child` (normal signed-in
    content), so splash/error/maintenance always rendered LTR even with a
    saved RTL language. Fixed by swapping the composition order in
    `main.dart`: `RtlScope(child: BootstrapGate(child: ...))` instead of
    the reverse, so `Directionality` now wraps all 4 of `BootstrapGate`'s
    branches. `MaintenanceScreen` now renders RTL correctly (it always has
    real resolved bootstrap data). Splash and a true network error
    honestly stay LTR — `isRtlProvider` can't know `is_rtl` before
    `bootstrapProvider` resolves — documented in `rtl_scope.dart`'s updated
    comment, not a cover for an incomplete fix. No on-device evidence:
    forcing real `maintenance_mode:true` on the live beta backend would
    affect real traffic, judged unsafe; relied on
    `test/features/bootstrap/rtl_scope_integration_test.dart`'s 3 new
    widget tests instead, which construct the exact same composition as
    the fixed `main.dart`. Non-vacuous: reverted the test's composition
    order, got a real RTL/LTR mismatch reproducing the bug, restored. Full
    suite (231 tests, incl. `widget_test.dart`'s real `TriptelApp` smoke
    test) green. Reviewer: PASS, independently reproduced the mutation
    test and grepped for any other `BootstrapGate` consumer (none found).
    Commits: `692e4ac` (feature), `a36917e` (state).
  - **FR-105b, FR-201b, FR-202b marked `blocked`** (were `not_started`,
    silently skipped by a prior session without a blocked_reason — see
    the 2026-11-13 DECISIONS.md entry on returning to strict order).
    Checked each for real: FR-105b needs a real
    `require_password_changed`-gated endpoint, which per `docs/API.md`'s
    own error text ("before buying or moving money") only exists on
    checkout (FR-301+) or wallet top-up/withdraw (FR-601+/FR-701+) calls —
    all `not_started`, so there's genuinely no producer to wire navigation
    to yet. FR-201b needs real eSIM usage data (FR-402/403) and referral
    context (FR-801) — also all `not_started`. FR-202b is blocked on the
    backend itself: `GET /catalog/countries` returns `CountryResponse`
    rows with no `is_featured`-equivalent field (that only exists on
    `ProductResponse`) — no API-driven way to pick a featured regional
    entry without a backend change. All three now carry a `blocked_reason`
    instead of sitting silently `not_started`. Commits: `e3de2cb`
    (FR-105b), `3a2bf63` (FR-201b/FR-202b).
- 2026-11-13 — Session 10 continued (FR-206, FR-005b):
  - **FR-206 (shareable destination link):** new share `IconButton` in
    `DestinationPlansScreen`'s header, calling `SharePlus.instance.share`
    with the pure `destinationShareUrl(slug)` helper
    (`https://triptel.co/explore/<slug>`). Widget test fakes `SharePlatform`
    via `plugin_platform_interface`'s documented `MockPlatformInterfaceMixin`
    pattern (added `plugin_platform_interface` and
    `share_plus_platform_interface` as dev_dependencies — both already
    transitive deps of `share_plus`, just made explicit for test code) to
    assert on the real `ShareParams` captured from a real tap. Non-vacuous:
    broke the URL to a wrong domain, got 3 real test failures, restored.
    On-device evidence (`artifacts/FR-206.png`) shows the actual Android
    native share sheet, reached via genuine navigation, displaying
    `https://triptel.co/explore/japan`. Reviewer: PASS first pass. Commits:
    `87f1ea6` (feature), `f26c1ac` (state).
  - **FR-005b (test-quality follow-up):** added 3 tests reading
    `selectedCurrencyRateProvider.future` directly (EUR default, a real
    non-EUR rate, recompute after `select()`) — previously only
    `resolveRate`'s pure-function tests existed, not the provider's own
    Riverpod wiring. No UI/production change, no device evidence needed.
    Non-vacuous: broke the provider to always return 1.0, got 2 real
    failures, restored. Reviewer: PASS, independently re-ran the mutation
    test itself. Commits: `ee8646d` (feature), `6910fb6` (state).
  - **Process correction:** the previous session's "low-priority, not
    urgent" skip of FR-005b/FR-006b/FR-105b (deferring them past FR-201+ in
    practice) wasn't actually blocked — just deprioritized by judgment call,
    without logging that deviation in DECISIONS.md. Per CLAUDE.md's strict
    "pick the active item, else the first `not_started` item" rule, this
    session picked FR-005b next (first `not_started` in array order) rather
    than continuing to skip ahead. FR-105b may still turn out to be
    legitimately blocked (it needs a real gated endpoint) — check when
    reached, and only mark `blocked` with a reason if so, don't just skip.
- 2026-11-13 — Session 10 continued (FR-205):
  - **FR-205 (plan detail/coverage sheet):** new `plan_detail_sheet.dart`
    — a modal bottom sheet opened via a new "Plan details" `TextButton`
    (keyed `plan-details-${product.id}`) under each plan row in
    `DestinationPlansScreen` (FR-204). Shows the full disambiguating
    `titleEn` (products can share data+validity, differing only by
    supplier suffix, e.g. "Japan 1GB 7Days" vs "(IIJ)" per API.md §3),
    three plan facts (data-type label via `planShape`, "Starts on
    install", "Personal hotspot"), and a Coverage section: the real
    `coverage_countries` list + count for regional products, or a plain
    "{countryName} · 1 country" row for the normal single-country case
    (same reasoning as FR-204's row-level coverage label — this app's
    `GET /catalog/destinations/{slug}` only ever returns non-regional
    products).
  - 5 new tests (4 in `plan_detail_sheet_test.dart`, 1 added to
    `destination_plans_screen_test.dart` for the real tap-through). Full
    catalog suite: 54 tests green. Non-vacuous: broke
    `isRegionalCoverage`'s condition, confirmed real compile/test failures
    in `plan_detail_sheet_test.dart`, restored, confirmed green again.
    `flutter analyze` clean, `dart format` no changes, `bash harness.sh
    verify` green.
  - On-device evidence (`artifacts/FR-205.png`, device
    `109973842B010285`): reached via genuine navigation (Home → Japan →
    "Plan details"), shows the real single-country path ("Japan · 1
    country"). The regional-coverage branch is unit-tested but not
    reachable live for the reason above — disclosed in
    `feature_list.json`'s evidence notes, same pattern as FR-201b/FR-202b.
  - Reviewer: PASS on first pass (checked FR text's 4 named facts are all
    rendered, null-safety on `coverageCountries`, real entry point,
    non-vacuous tests via its own mutation test, no redundancy with
    FR-204's row). Flagged only that the on-device screenshot hadn't been
    captured via `bash harness.sh shot FR-205` yet — fixed before marking
    passing.
  - Commits: `153ca7e` (feature), `b350845` (state).
- 2026-11-13 — Session 10 continued (FR-204, the biggest feature this
  session):
  - **FR-204 (destination plans screen):** `DestinationPlansScreen`
    (`/explore/<slug>`) — curved purple header (same gradient as the
    pre-existing `HeroHeader`, flag, name, `CurrencyPillSwitcher`); a
    `SegmentedPill` plan-type toggle shown only when 2+ shapes genuinely
    exist for the destination; `PlanWheelPicker` (reused) over the shape's
    primary dimension (data size for Fixed, validity days for Day
    Pass/Unlimited); a radio list of `PlanOptionTile` (reused) rows for
    products matching the wheel's current value, sorted price-ascending;
    "Recommended" suffix for `is_featured`; a sticky `StickyTotalBar`
    (reused) whose "Continue" is genuinely disabled (`onPressed: null`,
    not a visual trick) until a plan is selected, and shows "Checkout is
    coming soon" when tapped since checkout (FR-301+) doesn't exist.
  - New `Product`/`Destination` models (`GET /catalog/destinations/{slug}`,
    API.md §3) and a pure `plan_shape.dart`: `planShape()` follows API.md's
    exact detection table (checks `is_unlimited` BEFORE
    `supplier_period_num`, so a hypothetical product with both set
    correctly resolves to Unlimited, not Day Pass); `planDataLabel()`
    computes the Day Pass PER-DAY share by dividing `dataAmountGb` by
    `validityDays`, since the API documents that field as the *total* over
    all days on a day pass, not a per-day figure. Money: `retailPrice` via
    the pre-existing `Money.parseEur`; `product.currency` (which the beta
    mislabels "USD") is never read anywhere.
  - Closed the loop this session had been building toward since FR-202:
    non-regional taps in the explore sheet, and Home's own "Popular
    destinations" row taps, now navigate to this real screen instead of
    showing "coming soon" — the first destination-row taps in the whole
    session to land somewhere real rather than a placeholder snack.
  - **First-pass reviewer FAIL, fixed same session (third time this
    pattern has appeared):** FR-204's text and Design_System.md both list
    "coverage" as a distinct required row fact (title, validity, per-day
    label, coverage, price) — the first build's single caption slot only
    showed data-label + validity, dropping coverage entirely. Fixed by
    adding `planCoverageLabel()`: `GET /catalog/destinations/{slug}` can
    only ever return a single country's own (non-regional) products
    (confirmed against API.md §3's regional/`coverage_countries` rule), so
    every row's coverage is always "1 country" in practice, with a
    defensive fallback to the real `coverage_countries` length. **Pattern
    now seen three times this session** (FR-953's stale verification
    command, FR-203's missing row-level subtitle, now this): an FR's
    literal text enumerating several distinct UI facts is easy to
    half-satisfy by overloading one existing slot/field with only some of
    them. Worth explicitly counting the named facts in an FR against what
    actually renders before calling a row/screen "done," not just
    checking that *something* appears in roughly the right place.
  - 24 new tests; non-vacuous twice (`planShape`'s `isUnlimited` check,
    then separately `planCoverageLabel`'s fallback). Full suite (217
    tests) passes; `flutter analyze` clean; `bash harness.sh verify`
    green. On-device evidence (OPPO device, live beta data, reached via a
    real in-app tap — no router hack needed): Japan's real plan-type tabs
    (confirming it genuinely has all three shapes), the data-size wheel,
    a matching plan at a real EUR price with "100 MB · 7 days · 1
    country"; plan selection updating the radio + CTA; the Unlimited tab
    showing two real distinct matches at the same validity (the
    multiple-matches-per-wheel-value case).
  - Commits: `1c8a25c` (feature), `b247ba4` (state).
- 2026-11-13 — Session 10 continued (FR-203):
  - **FR-203 (regional list with coverage sheet):**
    `CatalogApi.getCoverageCountries(iso2)` (new) calls `GET
    /catalog/countries/{iso2}/products` and reads the first product's
    `coverage_countries` (confirmed — and independently re-confirmed by
    the reviewer — identical across a regional package's products, so the
    first one is enough). `coverageCountriesProvider` (family, keyed by
    iso2) feeds a new `CoverageSheet` (tap a regional row -> real list of
    covered countries, e.g. AUKUS(3 countries) -> Australia/United
    Kingdom/United States) and a new `_RegionalRow` widget that shows a
    real, live "N countries" subtitle on every Regional-tab row.
  - **First-pass reviewer FAIL, fixed same session:** the initial build
    only wired the tap-to-open-coverage-sheet behavior and skipped the
    row-level subtitle, reasoning that the catalog's own display names
    already embed an (inconsistent) count. The reviewer correctly held
    FR-203's literal text and the design reference to account — "Globe
    icon rows, name, 'N countries' *link*" describes a distinct per-row
    element, not just the name string. Fixed by adding `_RegionalRow`,
    which derives its subtitle from the same live `coverageCountriesProvider`
    the sheet itself uses (so the row and the sheet never disagree), with
    no subtitle shown while loading/on error rather than a wrong flash.
    **Lesson reinforced:** when an FR's literal text describes two
    distinct UI elements (a row *and* a link within it), treat consuming
    one existing data source for a reasonable-sounding combined behavior
    as a hypothesis to get reviewed, not a given — this is the second time
    this exact pattern (FR text implies a connected-but-separate UI piece
    that got collapsed into one) has needed a fix-after-review this
    session (the first was FR-953's verification-command gap).
  - Note: the catalog's own embedded count (e.g. "Asia (20 areas)") and
    the live coverage-list count ("19 countries") can legitimately differ
    — one is the supplier's own loose area/package count, the other is
    the actual `coverage_countries` list length. This is expected, not a
    bug, and is called out in the evidence notes so a future session
    doesn't mistake it for one.
  - 9 new tests; non-vacuous both times (coverage-sheet branch, then the
    subtitle derivation). Full suite (196 tests) passes; `flutter
    analyze` clean; `bash harness.sh verify` green.
  - Commits: `e5c8519` (feature), `ce63b02` (state).
- 2026-11-13 — Session 10 continued (FR-202):
  - **FR-202 (destination search sheet):** new `ExploreSheet`
    (`lib/features/catalog/presentation/explore_sheet.dart`), a full-height
    `showModalBottomSheet`: search pill, horizontally-scrollable
    `SegmentedPill` for Country/Regional (same overflow-safety precaution
    as FR-952, which had a real bug there), a "Popular" flag-chip row, and
    an A-Z sectioned list. Pure split/grouping logic in
    `country_grouping.dart` (`countryTabEntries`/`regionalTabEntries` by
    `Country.isRegional`, `groupByFirstLetter`). Search is genuinely
    debounced (400ms `Timer`, cancelled per keystroke) against the real
    `GET /catalog/countries?search=`, not client-side filtering.
  - Home's search pill and "Buy data" quick action now open this sheet
    instead of showing "coming soon" — the first of this session's several
    `_comingSoon` placeholders to get upgraded to a real destination, now
    that FR-202 exists (same FR-105b-style reasoning used throughout:
    don't route to what doesn't exist, do route once it does).
    Destination-row taps (both in the sheet and in Home's own "Popular
    destinations" list) still show "coming soon", since FR-204
    (destination plans screen) still doesn't exist.
  - Design_System.md's Explore row also specs a featured "Global" package
    card at the top of the sheet; deferred as `FR-202b` — confirmed via
    API.md that `CountryResponse` has no `is_featured`-equivalent field
    (only `ProductResponse` does), so there's no API-driven signal for
    which regional entry (there's a real "Global (120+ areas)" one in the
    beta catalog) should be featured yet.
  - 9 new tests (21 total in `test/features/catalog`); non-vacuous
    (inverted `countryTabEntries`' region predicate, got a real failure,
    restored). Full suite (189 tests) passes; `flutter analyze` clean;
    `bash harness.sh verify` green.
  - On-device evidence reached via a real in-app tap for the first time
    this session for a catalog sub-screen (no temporary-router hack
    needed, unlike FR-951/952/201's early captures): the Country tab with
    real popular chips and a real A-Z list, the Regional tab with real
    package names and globe icons, and a live debounced search for
    "japan" returning real results (including regional packages
    containing Japan) — confirming it genuinely hits the live API.
  - Reviewer agent: PASS on the first pass (no fix-then-re-review cycle
    needed this time).
  - Commits: `0dec26b` (feature), `1eed366` (state).
- 2026-11-13 — Session 10 continued (FR-201, plus user-driven UX trims):
  - **FR-201 (Home):** first catalog feature, built from scratch —
    `lib/features/catalog/{data,application,presentation}/`. `Country`
    model for `GET /catalog/countries` rows (API.md §3);
    `CatalogApiImpl.getCountries({search, popularOnly})`;
    `popularCountriesProvider` (cached for the session, same pattern as
    FR-950's `esimVerdictProvider`). `HomeScreen` rebuilt: `HeroHeader`
    (reused, pre-existing dark-gradient component) with a search pill and
    a "Buy data" quick action, the `CompatibilityPromoCard` (FR-953,
    reused not duplicated), and a real "Popular destinations" list via
    `CountryRow` (shared, pre-existing) fed by live beta data.
  - Destination search (FR-202) and the destination plans screen (FR-204)
    don't exist yet, so the search pill / "Buy data" / destination-row
    taps show a "`<thing>` is coming soon" snackbar instead of routing to
    a path that doesn't exist (same reasoning as FR-105b). The referral
    promo card and "signed-in users with an active eSIM see a usage
    summary instead of the hero" sub-behavior need FR-801/FR-402/403
    (none built) — deferred as a new `FR-201b` entry.
  - `test/fixtures/catalog_popular_countries.json` is a real captured
    response from `curl https://beta.triptel.co/api/v1/catalog/countries
    ?popular_only=true` (11 real countries), backing `Country.fromJson`'s
    test. 10 new tests; non-vacuous (broke `popularOnly: true`→`false` in
    the provider, broke the "My eSIMs" quick action's `onTap`, got real
    failures both times, restored).
  - **Gotcha:** all 5 pre-existing full-`TriptelApp` tests (`widget_test.dart`,
    `shell_test.dart`, `deep_link_routing_test.dart`, `auth_route_bridge_test.dart`,
    `compatibility_promo_test.dart`) needed
    `popularCountriesProvider.overrideWith((ref) async => const [])` added
    — without it, `HomeScreen`'s real provider fires an unmocked `Dio` call
    during the test, leaving a pending `Timer` that fails Flutter's
    teardown invariant check. Same category of fix as FR-953's
    `esimVerdictProvider` override, just one provider further down the
    dependency chain. **Lesson:** any new eagerly-watched real-network
    provider on `HomeScreen` (or any screen reachable from the full-app
    test harness) needs this treatment preemptively, not just on first
    failure.
  - **Gotcha:** `lib/app/app_shell.dart`'s bottom-nav tab buttons had no
    keys; adding a "My eSIMs" hero quick action with the identical label
    as the "My eSIMs" bottom tab made `find.text('My eSIMs')` ambiguous in
    `shell_test.dart` (2 matches). Fixed by giving each `_TabButton` a
    `ValueKey('tab-<label>')` and updating the test to use `find.byKey`.
    Worth remembering for any future screen content that might echo a
    bottom-tab label.
  - **User feedback mid-build** (unprompted, after seeing the on-device
    screenshots): flagged that the hero's "My eSIMs" quick action
    literally duplicated the bottom tab right below it (same label, same
    destination), and asked why "Check device compatibility" appeared on
    both Home and Account when FR-953 only strictly needed one real entry
    point. Also separately asked where "Buy data" and "Top up" actually
    navigated to, surfacing that "Top up" silently landed on the exact
    same `/wallet` route as the "Wallet" bottom tab (different label, same
    destination, since FR-408's real top-up flow doesn't exist yet).
    Resolved via `AskUserQuestion`: removed "My eSIMs" and "Top up" from
    the hero (left only "Buy data", which still has a real distinct
    "coming soon" purpose since FR-202 doesn't exist); removed the
    `CompatibilityPromoCard` from Account, keeping it on Home only.
    Updated both features' tests accordingly (asserting absence instead of
    presence+navigation) and FR-953's already-committed `feature_list.json`
    evidence notes (which had gone stale the moment the Account card was
    removed) with an explicit "UPDATE" paragraph rather than silently
    rewriting history. Recaptured both affected on-device screenshots.
    **Lesson reinforced:** a feature matching its FR's literal text isn't
    the same as it making UX sense once actually seen on a real device —
    the user caught real redundant-button UX smell purely from screenshots
    that passed every automated check. Worth proactively asking "does this
    duplicate an existing nav target?" before adding new shortcut buttons,
    not just after being asked.
  - Reviewer agent (run twice — once on the original FR-201 build, once
    after the three UX trims together with FR-953's Account-card removal):
    both PASS, the second catching one real issue (FR-953's evidence notes
    were stale after the Account-card removal) which was fixed before
    committing.
  - Full suite (178 tests) passes; `flutter analyze` clean; `bash
    harness.sh verify` green throughout. On-device evidence (OPPO device,
    live beta data): real flag images loaded for the popular-destinations
    list, working "coming soon" snackbars, real navigation to My eSIMs via
    the (now sole) hero action path, and the final Account screen
    confirmed to no longer show the compatibility card.
  - Commits: `16c0a30` (feature), `01444b9` (state).
- 2026-11-13 — Session 10 continued (FR-953, resumed by user request after
  the FR-952 stop):
  - **FR-953 (compatibility everywhere it matters):** new
    `CompatibilityPromoCard` (`lib/features/compatibility/presentation/`),
    shared between `HomeScreen` and `AccountScreen` — the first real in-app
    entry point to `/compatibility`/`/compatibility/devices` (FR-951/952
    were built route-first with no trigger, same pattern as FR-003/FR-109;
    this closes that gap). Checkout gate (FR-301) and install gating
    (FR-404/FR-310) can't be wired yet since neither screen exists yet
    (both `not_started`) — deferred as a new `FR-953b` entry, same
    incremental pattern as FR-005b/FR-105b/FR-106.
  - Both `HomeScreen`/`AccountScreen` changed their outer `Column`'s
    `crossAxisAlignment` from `.end` to `.stretch` to let the new full-width
    card render correctly; the pre-existing currency/language pill
    switchers were wrapped in `Align(alignment: Alignment.centerRight)` to
    keep their original small, top-right-pinned look unchanged under the
    new stretch — confirmed visually unchanged in the on-device screenshots.
  - 2 new tests (`test/app/compatibility_promo_test.dart`) prove the full
    navigation chain on both screens; non-vacuous (changed the card's
    `onTap` to a no-op, both tests failed with "Found 0 widgets with type
    CompatibilityResultScreen", restored). Full suite (168 tests) passes;
    `flutter analyze` clean; `bash harness.sh verify` green.
  - Evidence is genuine on-device capture on a 4th different physical
    device this session (a Tecno BG6) — and for the first time, via the
    *real* entry points (no temporary-`initialLocation` trick needed, since
    FR-953 is exactly what made the route reachable by tapping through the
    actual app): tapped the promo card on Home, landed on the real
    `CompatibilityResultScreen` showing that device's real verdict ("TECNO
    TECNO BG6", "Your device does not support eSIM"); switched to Account,
    confirmed the card renders there too, cleanly positioned above the
    existing Create account/Sign in buttons.
  - Reviewer agent: first pass FAIL — FR-953's own declared verification
    command (`flutter test test/features/compatibility && ...`) never
    actually exercised the new promo-card/Home/Account code at all (that
    test directory only contains the pre-existing FR-951/952 tests), which
    would have violated WIP=1's "verification command must fail when the
    feature is reverted" rule. Fixed by pointing the command at the real
    test file (`flutter test test/app/compatibility_promo_test.dart`);
    re-reviewed: PASS. **Lesson reinforced:** when a new feature's tests
    land in a *different* directory than the FR's pre-filled
    `feature_list.json` verification command assumes (e.g. a shared/cross-
    screen component tested under `test/app/` rather than the feature's own
    `test/features/<x>/`), double-check the verification string actually
    points at the new test file before marking passing — don't just trust
    whatever was pre-filled in the initial `feature_list.json` scaffold.
  - Commits: `3f62022` (feature), `a006a6c` (state).
  - Compatibility section (K) is now fully done except FR-953b, which waits
    on checkout/eSIM-detail screens that don't exist yet.
- 2026-11-13 — Session 10 continued (FR-952, then stopped by user request):
  - **FR-952 (supported devices list):** `SupportedDevicesScreen`
    (`lib/features/compatibility/presentation/`) — curated device list by
    brand (`lib/features/compatibility/data/models/compatible_device_group.dart`,
    `CompatibleDeviceGroup`), faithfully ported from the web storefront's
    `frontend/src/app/guides/compatible-phones/page.tsx` `DEVICES` constant
    (brand labels shortened to match FR-952's literal "Apple · Samsung ·
    Google · Other" wording; model strings copied verbatim since this is
    factual device data, not marketing copy, and the FR text itself says
    "ported from web"). Search is scoped to the selected brand
    (`filterDeviceModels`, pure/tested in `device_search.dart`). `*#06#`
    EID check tip and an OS settings-path fallback, both original Triptel
    wording. FR-951's result screen got a new "View supported devices"
    button linking here (`/compatibility/devices`), closing the loop its
    own FR text described.
  - **Real bug caught by on-device testing, not by any test file:** the
    brand filter chip row (`SegmentedPill` wrapping 4 options) overflowed
    horizontally on a real phone's screen width — visible as a
    "RenderFlex overflowed" debug-mode error strip in the very first
    screenshot captured. Fixed by wrapping it in a horizontally-scrollable
    `SingleChildScrollView`. Added a regression test (`tester.view.physicalSize
    = Size(360, 800)`, asserts `tester.takeException()` is null), proven
    non-vacuous by removing the fix and confirming the exact same class of
    overflow error, then restoring. **Lesson reinforced:** widget tests at
    the default test viewport size don't catch layout overflow on narrower
    real screens — worth a deliberate narrow-width test for any
    horizontal `Row`/`SegmentedPill`-style layout with a variable number
    of items.
  - 35 compatibility tests pass (166 total suite-wide); `flutter analyze`
    clean; `bash harness.sh verify` green (debug APK built). Evidence is
    three genuine on-device screenshots (same temporary-`initialLocation`
    capture technique as FR-951, reverted after capture, `/home` confirmed
    still loading normally both times): default Apple-selected view with no
    overflow, the chip row scrolled to reveal "Other", and "Other" selected
    showing Huawei/Oppo/Sony/Motorola/Honor models.
  - Reviewer agent independently reproduced the overflow-bug regression
    test itself (not just read the code) before passing: PASS.
  - Commits: `9a32625` (feature), `945ae70` (state).
  - **User explicitly asked to stop the autonomous loop after this feature's
    commit** — session ends here. Compatibility section (K) is now FR-950/
    951/952 passing, FR-953 ("everywhere it matters") not started. Do not
    pick up FR-953 automatically next session without being told to; it's
    simply the logical next item in `feature_list.json` order, nothing more.
- 2026-11-13 — Session 10 continued (FR-950 unblocked, FR-951):
  - **FR-950 unblocked -> passing.** A different physical device (OPPO
    CPH2015, Android 9/API 28, no eUICC, serial `YP7HDIPFPBWGHM9H`) was
    connected mid-session; `flutter test integration_test/fr_950_test.dart
    -d YP7HDIPFPBWGHM9H` passed cleanly on the first try ("getEsimSupport
    channel returns a real, decidable verdict" — All tests passed!),
    confirming the vivo V2344's `flutter_tools`<->`adb` logcat-streaming
    issue (documented in the FR-950 entry below) was genuinely a
    device/environment problem, not a code defect. Flipped FR-950 to
    `passing` with both the unit-test and this device's integration-test
    evidence.
  - **FR-951 (compatibility result screen):** `CompatibilityResultScreen`
    (`lib/features/compatibility/presentation/`) watches `esimVerdictProvider`
    and renders Eskimo's result-tinted pattern re-skinned in Triptel tokens
    — success/warning/danger tint + icon + headline per verdict kind (amber
    "unknown" is its own distinct treatment, never collapsed into red
    "not supported", per Rules.md), a `StatusChip` device label, explanation
    text, and a carrier-lock `InfoBox` with original Triptel wording (not
    copied from Eskimo's reference screenshot text). New `/compatibility`
    route added to the router; it has no live entry point in the app yet —
    that's FR-953 ("compatibility everywhere it matters": home promo,
    Account entry, checkout gate, install gating), same
    build-screen-before-its-trigger pattern as FR-003/FR-109.
  - 23 tests pass (5 new screen tests: supported/notSupported/unknown/
    loading/error), non-vacuous (broke the notSupported headline string,
    got a real failure, restored). `flutter analyze` clean; `bash
    harness.sh verify` green (154 tests, debug APK built).
  - Evidence is a genuine on-device screenshot, not a widget-test render:
    temporarily set `router.dart`'s `initialLocation` to `/compatibility`
    (since there's no button to tap there yet), rebuilt the debug APK,
    installed + launched it on the OPPO CPH2015, screenshotted with `adb
    exec-out screencap`, then reverted `initialLocation` back to `/home`,
    rebuilt again, and reinstalled + relaunched to confirm `/home` still
    loads normally (`git diff lib/app/router.dart` showed only the
    permanent `/compatibility` route addition — the temporary experiment
    left no trace). The resulting screenshot shows the real verdict for
    that device: chip "OPPO CPH2015", red header, "Your device does not
    support eSIM", "This device has no eSIM hardware." — correct, since
    that phone has no eUICC feature.
  - Gotcha: an early attempt at a widget-test `RepaintBoundary` screenshot
    of this screen (same technique used successfully for FR-109) produced a
    visually duplicated render (the whole screen painted twice, stacked) at
    a tall custom `tester.view.physicalSize` (1080x2340); shrinking the test
    viewport to fit the actual content (1080x1200) fixed it. Root cause not
    fully diagnosed (not worth the time once a real on-device screenshot
    became available via the temporary-route trick above) — if this
    resurfaces, prefer a real on-device capture over debugging the
    widget-test render artifact further.
  - Commits: `6ad0832` (FR-951 feature), `3218f93` (state: FR-950 + FR-951
    passing).
- 2026-11-13 — Session 10 (FR-950, blocked on device tooling):
  - Built the pure decision logic for eSIM-support detection:
    `lib/features/compatibility/{data,application}/` — `EsimSupportChannel`
    wraps the pre-existing native `co.triptel.app/esim` channel
    (`MainActivity.kt`/`AppDelegate.swift`, both written in session 0, not
    touched this round); `evaluateEsimSupport()` is the pure verdict
    function matching FR-950's decision table exactly (Android API<28 ->
    unknown; no EUICC feature -> notSupported; EUICC feature + enabled ->
    supported; EUICC feature present but disabled/locked -> **unknown**, not
    notSupported, per Rules.md "unknown is not not supported"; iOS uses
    `supportsEmbeddedSIM` when available, else falls back to
    `supportsCellularPlan`, else unknown). iOS machine-id -> marketing-name
    map for display. `esimVerdictProvider` is a plain (non-autoDispose)
    `FutureProvider`, cached for the app session per Architecture.md.
  - 18 unit/provider tests pass (`flutter test test/features/compatibility`),
    `flutter analyze` clean, `bash harness.sh verify` green (149 tests
    total). Proven non-vacuous: disabled the Android `enabled == true`
    branch, got a real test failure, restored, green again. No device
    signals ever reach the API (grepped for dio/http/ApiClient in the
    feature folder — none), matching the NFR "device compatibility data
    never leaves the device".
  - **Blocked, not passing:** the FR's own verification command also
    requires `flutter test integration_test/fr_950_test.dart -d
    10EF1302BJ000R5` (a real on-device run of the native channel). This
    failed identically 5 times in a row — `Error waiting for a debug
    connection: The log reader stopped unexpectedly` — across an adb server
    restart, a logcat buffer clear, enabling the vivo Developer Options
    "USB debugging (Security settings)" toggle, and a full USB
    disconnect/reconnect. Manually confirmed via `adb shell pidof` (stable
    across repeated checks) and a logcat scan that the app itself launches
    and runs fine — this is a `flutter_tools`<->`adb`<->vivo
    logcat-streaming interaction issue on this machine/device, not a code
    defect. The reviewer agent independently reproduced the same failure
    mode on its own run (a 5th/6th data point) and confirmed PASS on
    everything else. Set `blocked` with a detailed `blocked_reason`; will
    retry once a different cable/port/device is available.
  - Gotcha: on this vivo V2344 + Windows setup, `flutter test
    integration_test/*.dart -d <device>` (which needs a live VM-service
    debug connection via adb logcat) is unreliable, while plain `adb exec-out
    screencap`/`adb shell am start`/`pidof` (used all session for UI
    evidence) are completely reliable. Prefer the latter path for on-device
    verification where the feature doesn't specifically need the Dart VM
    attached; FR-951/952 verify via `harness.sh shot`, which uses the
    reliable path.
  - Commits: `9ccd83a` (feature), `25c05e1` (state).
- 2026-11-13 — Session 9 continued (FR-109):
  - Suspended-account screen on a 403 "Account suspended" (API.md §0.1).
    New `AuthSuspended` AuthState variant; `postAuthRoute()` returns
    `/suspended` for it. `AuthNotifier.build()` (session restore),
    `login()`, and `loginWithGoogle()` all clear the token and set
    `AuthSuspended` on that 403 (never saving a token for it); other
    `ApiException`s still rethrow as before. New `SuspendedScreen` mirrors
    FR-003's maintenance screen (support email/phone from `/settings/public`,
    hidden if both null). New `AuthRouteBridge` (wraps the whole app in
    `main.dart`, inside `DeepLinkBridge`/outside `BootstrapGate`) listens
    globally for the transition into `AuthSuspended` and routes to
    `/suspended` — needed because an already-signed-in user whose session
    restore discovers suspension has no login-screen interaction to trigger
    navigation otherwise (FR-107's restore path). Login's own `403` handling
    (which used to show an inline "Account suspended" error, from FR-102)
    now goes through the same `AuthSuspended` state instead.
  - 131 tests pass; `flutter analyze` clean; `bash harness.sh verify` green
    (debug APK built). Proven non-vacuous twice: (1) disabled the
    `isSuspended` branch, `auth_providers_test.dart`'s 3 new suspension tests
    failed for real, restored, green again; (2) broke `AuthRouteBridge`'s
    listener condition to `if (false)`, the new
    `test/app/auth_route_bridge_test.dart` failed ("0 widgets found, expected
    1"), restored, green again.
  - No real suspended beta account exists, so the live-backend 403 can't be
    driven end-to-end on-device (same disclosed limitation as FR-105's
    positive case). Evidence instead: `artifacts/fr-109/02-home.png` — a
    post-change device smoke test showing a normal signed-in session still
    resolves to `/home` (no accidental suspension regression); and
    `artifacts/fr-109/03-suspended-screen.png` — a widget-test
    `RepaintBoundary` capture of the real `SuspendedScreen` showing its
    actual layout (icon, headline, body, support-contact pill). Text in
    that capture renders as placeholder glyph boxes because `flutter test`
    doesn't load real fonts; the exact text content is separately asserted
    by `suspended_screen_test.dart`'s `find.text(...)` checks, so this is a
    structural, not typographic, screenshot.
  - Reviewer agent: first pass FAIL (no test exercised `AuthRouteBridge` at
    all — `flutter test test/features/auth` would still pass if it were
    deleted; no screenshot evidence of `SuspendedScreen` existed). Both
    fixed as above; re-reviewed: PASS.
  - Gotcha: capturing a widget's `RepaintBoundary` to PNG inside a
    `flutter test` run (not an integration/device test) is a decent
    structural-screenshot fallback when a real device/account path is
    genuinely unavailable — just disclose the no-real-fonts caveat.
  - Commits: `77d9f37` (feature), `8959d9d` (state).
- 2026-11-13 — Session 9 continued (FR-108):
  - `AuthNotifier.logout()` itself predates this round (built in FR-101's
    session); gave it dedicated, meaningful coverage now that FR-107 exists
    to make persistent-storage assertions actually prove something. 2 new
    tests: `SecureStore` genuinely cleared (not just in-memory `AuthState`),
    and a fresh `ProviderContainer` over the same storage (simulating an
    app relaunch) correctly restores to signed-out. Confirmed no other
    account-scoped cache exists anywhere in the app today (currency/language
    prefs are device-level, correctly untouched by logout).
  - Proven non-vacuous. `bash harness.sh verify` green (123 tests).
    On-device, the strongest proof the session had evidence for yet: signed
    in → tapped Sign out → reverted immediately → real `adb shell am
    force-stop` (full process kill) + cold relaunch → still signed out.
    Since FR-107's restore logic was already proven (same device, same
    session) to pick up a real stored token, this negative result is solid
    proof `logout()` genuinely deleted the token from OS-level storage.
  - Reviewer agent: PASS.
  - Commits: `2412543` (test code), `5be0a8b` (state → passing).
- 2026-11-13 — Session 9 continued (FR-106 evaluated/blocked, FR-107):
  - **FR-106** evaluated and marked `blocked`, not built: resuming a guest
    purchase needs a real purchase attempt to persist from and a real
    checkout to resume into, and neither exists yet (catalog FR-201+ and
    checkout FR-301+ are all `not_started`). Unlike FR-007's referral
    provider (built ahead of FR-101's register screen, which already
    existed to consume it), FR-106 has no producer or consumer to wire to
    yet, and redirecting to a not-yet-registered go_router route would be
    unsafe. Logged to revisit alongside FR-301.
  - **FR-107**: `CurrentUser` model (`GET /auth/me`, API.md §2 — explicitly
    does NOT include `must_change_password`), `AuthApi.fetchCurrentUser()`.
    `AuthNotifier.build()` rewritten: reads a stored token, and if present
    reconstructs `AuthAuthenticated` by combining `/auth/me`'s
    role/userId/username with the stored accessToken AND the stored
    `must_change_password` flag (the REST response can't supply that part).
    A 401 clears the stored token and falls back to signed-out (API.md
    §0.1); any other failure propagates as an error without touching the
    token, so a transient network blip doesn't destroy a restorable session.
  - 3 new tests isolating the three branches (restore success, 401,
    non-401), proven non-vacuous. `bash harness.sh verify` green (121
    tests). On-device: a real JWT already in secure storage from earlier
    `salman2033` testing — after a full reinstall + force-stop + cold
    launch, the Account tab showed "Signed in as salman2033" with zero
    re-entered credentials, a strong proof of a real session restore
    against live beta.
  - User asked why BDT currency selection didn't fix right-to-left layout:
    explained currency (FR-005) and language (FR-006) are independent —
    RTL comes from the language pill (still set to Arabic from earlier
    testing), not the currency pill.
  - Reviewer agent: PASS.
  - Commits: `b3bfba5` (feature code), `29e20be` (state → FR-106 blocked,
    FR-107 passing).
- 2026-11-12 — Session 9 continued (FR-105):
  - `AuthToken.copyWith()`, `AuthApi.changePassword()` (POSTs
    `/auth/change-password`), `postAuthRoute(AuthState)` (pure: `/set-password`
    when `mustChangePassword`, else `/home`) feeding login/register/Google's
    post-success navigation.
  - `AuthNotifier.changePassword()` clears the flag in state + `SecureStore`
    on success, keeping the same access token (no new session); leaves it
    untouched on failure.
  - `SetPasswordScreen` — current/new password fields, success state, and a
    "Not now — go to My eSIMs" link; it's a normal routable screen (not a
    modal) with the 4-tab shell still reachable, so it never blocks viewing
    My eSIMs. Account's signed-in view also shows a defensive prompt for a
    user who skipped it earlier.
  - Deliberately left unwired: the 403 "set your own password" interception
    half, since no `require_password_changed`-gated endpoint exists yet
    (checkout/wallet are future FRs) — logged as **FR-105b** rather than
    faked. `ApiException.mustChangePassword` already exists for whichever FR
    calls the first gated endpoint.
  - 47 tests (auth + account), two non-vacuousness proofs. `bash harness.sh
    verify` green (118 tests). On-device: logged in with the real
    `salman2033` account (`must_change_password: false`) — correctly no
    prompt/redirect. The positive case has no real beta account to trigger
    it, so only widget-tested — disclosed, not faked.
  - Reviewer agent: PASS.
  - Commits: `10cf47c` (feature code), `3520305` (state → passing + FR-105b logged).
- 2026-11-12 — Session 9 continued (FR-104):
  - `ForgotPasswordScreen` — email field, client-side `validateEmail`
    (reused from FR-101), POSTs `/auth/forgot-password` via `authApiProvider`
    directly (not `authNotifierProvider` — this is a one-shot request, not a
    session change). Always shows the identical generic success message
    regardless of the response, matching API.md's "never enumerate" rule;
    the success copy explicitly says the link opens on the web, not in the
    app (no deep link exists for `/auth/reset-password?token=`).
  - "Forgot password?" link added to `LoginScreen`, mirrored correctly in
    RTL via `AlignmentDirectional.centerEnd`.
  - 4 new tests, proven non-vacuous (disabled the success state transition,
    watched 2 tests fail for real, restored). `bash harness.sh verify`
    green (107 tests). On-device: real `POST /auth/forgot-password` against
    live beta using the FR-101 test account — generic success shown with
    the required web-link disclaimer.
  - Reviewer agent: PASS, confirmed the no-enumeration property genuinely
    holds (no code path branches on whether the email exists).
  - Commits: `4b4e6d9` (feature code), `0c738c8` (state → passing).
- 2026-11-12 — Session 9 (FR-103):
  - `GoogleAuthService` wraps `google_sign_in` v7 (`GoogleSignIn.instance
    .initialize(serverClientId:)` then `.authenticate()`), deliberately thin
    and untested like `deep_link_listener.dart`'s plugin glue.
    `AuthApi.loginWithGoogle()`/`AuthNotifier.loginWithGoogle()` POST
    `/auth/google` with the ID token. `LoginScreen` shows "Continue with
    Google" only when `/settings/public.google_client_id` is non-null.
  - First on-device attempt: the button correctly opened the **real** Google
    account picker (proving `google_client_id` is live from beta and the
    plugin wiring works) — but completing a real sign-in twice in a row both
    returned `GoogleSignInException` "cancelled by the user". Diagnosed as
    no Android OAuth client registered for `co.triptel.app` + this machine's
    debug SHA-1 (the native SDK requires one even though only the web
    client id is sent to the backend). Confirmed with the user before
    attempting a real sign-in at all (touches their personal Google
    identity), gave them the exact Google Cloud Console steps + the debug
    SHA-1, marked `blocked`, moved to FR-103's Google-logo polish and FR-104
    groundwork while waiting.
  - User registered the Android OAuth client mid-session ("i have saved the
    aouth"). Rebuilt, reinstalled, retested: this time the flow reached a
    real "Allow Google to sign you in to Triptel" consent screen (only
    reachable with a correctly registered client) → Agree and share → real
    session established → Account tab showed "Signed in as
    mdimranhosenbd96". Flipped FR-103 to `passing`.
  - Added `GoogleLogo` (hand-drawn `CustomPainter` reproducing Google's
    official 4-colour "G" mark from its real SVG path data — no new asset
    or dependency) and a `PillButton.leading` slot, per the user's request
    for a logo on the button.
  - **Gotcha, handled carefully:** several intermediate screenshots during
    both on-device attempts showed the device owner's real name and Gmail
    address (the native account picker / consent screen). Each was viewed
    to confirm state, then deleted immediately — never written to
    `artifacts/` as committed evidence, never pushed. Only PII-free
    screenshots (button visible, derived-username signed-in state, clean
    error states) are in the repo.
  - 19+ tests (loginWithGoogle success/error, Google button shown/hidden by
    `google_client_id`, full flow via a fake `GoogleAuthService`, cancel
    handling, `GoogleLogo` sizing). `bash harness.sh verify` green.
  - Reviewer agent: PASS (reviewed twice — once for the built-but-blocked
    code, once after re-verification following the user's OAuth setup).
  - Commits: `87729cc` (initial feature code, blocked), `9a5e294` (state →
    blocked), `743d13f` (logo + re-verified working), `f78fe34` (state →
    passing).
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
9. **`GET /esims/{id}/status`'s `status.is_installed` telemetry doesn't reflect
   reality for eSIM Access-supplied eSIMs:** confirmed live (2026-11-16) against
   the real signed-in account -- a real eSIM the user reports actively using
   right now still returns `is_installed: false, is_activated: false,
   device_model: null`. Another (`865fe3a6...`, `activated_at` set 2026-11-11)
   returns `is_installed: false, is_activated: true` -- so even the backend's
   own `is_activated` flag can be true while `is_installed` stays false
   indefinitely. By contrast, two *older, now-expired* eSIMs do show
   `is_installed: true` with a real `device_model` ("iPhone 11 Pro Max"/"iPhone
   13 Pro"), so the signal CAN work -- it's unreliable/delayed specifically for
   current eSIM Access profiles, not universally broken. On-device screenshot
   (`artifacts/FR-403-backend-telemetry-gap.png`): the Bangladesh 1GB 7Days
   eSIM's own usage ring shows 1.72GB remaining (i.e. real data already
   consumed) and "15 days left" -- concrete evidence it's genuinely installed
   and in active use -- while `status.label` still says "Not installed yet".
   The client (FR-403's
   detail screen) correctly displays whatever `status.label`/`is_installed`
   the backend returns, per Rules.md ("treat only telemetry is_installed as
   installed"); there is no client-side bug here. **App-side mitigation
   already shipped:** FR-402's list chip no longer claims "Not installed" from
   the unrelated `/orders/my-esims` status enum (which never updates at all);
   it now says the lower-confidence "Ready to install" instead. FR-403's
   detail screen still echoes the backend's literal label/telemetry verbatim --
   that's the right behavior for a pure client, but it will keep looking wrong
   to users until the backend's own eSIM Access telemetry sync improves. Owner
   to investigate the eSIM Access polling/webhook integration.

## User actions pending
- Register an Android OAuth client (`co.triptel.app` + debug SHA-1) for Google Sign-In.
- Optional: `flutter upgrade` (≥ 3.35) to enable the Dart MCP server.
