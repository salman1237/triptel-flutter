# Functional Requirements — Triptel User App (Flutter)
**Read when:** building a feature. Every FR maps to one `feature_list.json` item
(same ID), sized to about one session. Endpoint details live in `docs/API.md`;
screen patterns live in `docs/Design_System.md`.

Sources, in priority order: the live beta backend → the web storefront
(`D:\eSim\frontend`) → the React Native app's FR doc (`D:\eSim\Triptel-MobileApp`),
which predates eSIM Access. If they disagree, the backend wins.

**Scope: customers only (USER role).** No admin, merchant, agent or partner screens.

---

## A. App shell & bootstrap
- **FR-001 Theme & design system.** Triptel purple/white theme tokens, typography,
  the shared components listed in `Design_System.md` §4. No screen ships with ad-hoc colours.
- **FR-002 Bootstrap.** On launch: `GET /settings/public`, `/settings/rates`,
  `/settings/languages`; cache for offline start; splash while loading.
- **FR-003 Maintenance gate.** `maintenance_mode == true` → blocking screen with
  support contacts and a retry button.
- **FR-004 Bottom navigation.** 4 tabs: **Home · My eSIMs · Wallet · Account**
  (Eskimo uses 3; Triptel needs My eSIMs as a first-class tab). Refer lives inside
  Wallet/Account; Support inside Account.
- **FR-005 Currency display & switcher.** Convert EUR → selected currency with rates;
  pill switcher in headers (Eskimo "USD $" pill). Persist via `PUT /auth/me/preferences`
  when signed in, locally otherwise.
- **FR-006 Language switcher & RTL.** Admin-controlled languages, translations from
  `/settings/translations/{code}`, RTL for `is_rtl`.
- **FR-007 Deep links.** `triptel://payment-callback?...` (payments) and incoming
  `https://triptel.co/track/<token>` / `?ref=CODE` links (best effort; universal
  links need backend `.well-known` files — logged gap).

## B. Auth & account access
- **FR-101 Register.** Email, username, password (≥ 8), optional phone/full name,
  optional referral code (pre-filled from a ref link, live-validated, FR-803).
- **FR-102 Login.** Email-or-username + password. Persist `must_change_password`.
- **FR-103 Google Sign-In.** ID token with `serverClientId = /settings/public.google_client_id`
  → `POST /auth/google`. Needs an Android OAuth client for `co.triptel.app` + SHA-1 (user action).
- **FR-104 Forgot / reset password.** Request link in-app; the email link opens the
  web reset page (no app link infra) — say so on screen.
- **FR-105 Forced password change.** `must_change_password` or the 403 "set your own
  password" → Set Password screen. Doesn't block viewing My eSIMs.
- **FR-106 Resume purchase after auth.** Persist `{productId, discountCode}` before
  sending a guest to login; resume checkout after login/register/Google.
- **FR-107 Session restore.** Token in secure storage → `GET /auth/me`; 401 → login.
- **FR-108 Sign out.** Delete token + cached user data.
- **FR-109 Suspended account screen.** On 403 "Account suspended".

## C. Discover
- **FR-201 Home.** Hero (Eskimo dark-hero pattern, Triptel deep purple), "Find your
  destination" search entry, quick actions (Buy data · My eSIMs · Top up), promo cards
  (referral, compatibility check), popular destinations (`popular_only=true`).
  Signed-in users with an active eSIM see a usage summary card instead of the empty hero.
- **FR-202 Destination search sheet.** Full-height sheet: search pill (debounced
  `GET /catalog/countries?search=`), **Country | Regional** segmented toggle
  (`region == "Regional"`), popular chips with round flags, A–Z sectioned list.
- **FR-203 Regional list.** Globe icon rows, name, "N countries" link → coverage list sheet.
- **FR-204 Destination plans screen.** `GET /catalog/destinations/{slug}`. Curved
  purple header (flag, name, currency pill). Plan-type toggle **Data · Day Pass ·
  Unlimited** (only types that exist). Wheel picker over data sizes (fixed) or days
  (Day Pass/Unlimited). Below: radio list of matching plans (title, validity,
  per-day label, coverage, price), "Recommended" badge for `is_featured`, sticky
  **Continue** CTA.
- **FR-205 Plan detail / coverage sheet.** Coverage countries for regional plans,
  plan facts (validity starts on install, hotspot, data type), disambiguating title.
- **FR-206 Shareable destination.** Share `https://triptel.co/explore/<slug>`.

## D. Checkout
State machine (port of web `PackageBrowser.tsx`):
`compat-check → review → (auth) → choose-payment → working | redirecting → success | preparing | error`.
- **FR-301 Pre-checkout compatibility gate.** Run FR-950; if not supported show the
  "Buy now, use later" dialog (Continue · View supported devices · Cancel); if
  unknown, a softer note. Never hard-blocks purchase.
- **FR-302 Checkout review screen.** Plan header, voucher row (opens code entry),
  price breakdown card (subtotal, discount, total), sticky total bar with
  "You save …", "Continue to payment" CTA.
- **FR-303 Discount code — guest estimate.** `POST /discounts/check`; scoped codes say
  "confirmed after sign-in".
- **FR-304 Discount code — authoritative.** `POST /discounts/preview` before charging;
  invalid → show `reason`, keep the user on review.
- **FR-305 Payment method chooser.** Bottom sheet: Wallet (shows balance & balance
  after) vs ShurjoPay. Wallet offered only if DEFAULT+REWARD ≥ total; otherwise go
  straight to ShurjoPay.
- **FR-306 Wallet checkout.** `POST /orders/checkout` → poll `GET /orders/{id}`
  (Rules: PROCESSING is not failure).
- **FR-307 ShurjoPay checkout.** `order-initiate` with `mobile:true` → WebView →
  `triptel://payment-callback` → poll the order.
- **FR-308 Provisioning progress.** Step list "Payment confirmed → Reserving your
  eSIM → Preparing QR"; then success.
- **FR-309 Still-preparing state.** After the poll window: "We're still setting up
  your eSIM — it will appear in My eSIMs and arrive by email." Not an error.
- **FR-310 Purchase success.** QR (FR-401), 1-tap install (gated by FR-950), copy
  codes, "Go to My eSIMs".
- **FR-311 Purchase failure.** Only on explicit `FAILED`; states the refund to wallet.

## E. My eSIMs
- **FR-401 eSIM QR component.** Error correction **H**, logo 22 % width on a white
  circular disc, app mark (not wordmark). Matches web `EsimQr.tsx` / backend `qr_branding.py`.
- **FR-402 My eSIMs list.** Cards (`GET /orders/my-esims`): plan title, status chip,
  data/validity, "starts on install" or expiry; pull to refresh; empty state → explore.
  Include "Bought for me" vs "Bought by me" (`is_beneficiary`).
- **FR-403 eSIM detail — usage.** `GET /esims/{id}/status`: usage ring/bar
  (allowance incl. top-ups; none for unlimited), remaining, validity countdown or
  "starts on install" note, status label, telemetry-stale banner, manual refresh
  (`POST /refresh`, 30 s cooldown).
- **FR-404 eSIM detail — install.** QR reveal, 1-tap install (iOS 17.4+/Android),
  manual SM-DP+ + matching ID + LPA (copy), "install only once" warning, link to
  setup guide. Install hidden on unsupported handsets (FR-950) with explanation.
- **FR-405 eSIM detail — lifecycle status.** Banners for `SUSPENDED`, `REVOKED`,
  `CANCELLED`, `EXPIRED`; disable install and top-up for them.
- **FR-406 eSIM detail — history.** Daily breakdown & install history when present (VivaPe).
- **FR-407 Top-up options.** `GET /esims/{id}/topup-options`; section hidden when empty.
- **FR-408 Top-up purchase.** Same chooser as FR-305: wallet `POST /esims/{id}/topup`,
  or ShurjoPay `esim-topup-initiate` → WebView → intercept
  `.../my-esims/<id>?topup=` → reload status.
- **FR-409 Share / receipt.** Share tracking link (`share_url`) via share sheet;
  printable/shareable receipt as PDF/image (order no, ICCID, QR, plan, price).
- **FR-410 Get help for this eSIM.** "Report a problem" → new ticket prefilled with
  category ESIM and `order_id`.

## F. Public tracking
- **FR-501 Track without login.** Open a `/track/<token>` link or paste it →
  `GET /esims/public/{token}`; read-only detail view; invalid → error + Support.

## G. Wallet
- **FR-601 Wallet overview.** Balance hero card (Eskimo Rewards card style):
  Main balance (DEFAULT), Reward credit (REWARD, "not withdrawable"),
  Commission only if > 0; actions Top up · Withdraw · Refer.
- **FR-602 Transaction history.** `GET /wallets/ledger` with filter by wallet type,
  human labels for `reference_type`, credit/debit colouring.
- **FR-603 Top up via ShurjoPay.** Amount in the user's currency, presets + custom,
  EUR limits from settings; WebView → intercept `.../wallet?topup=` → reload wallets.
- **FR-604 Manual deposit.** Choose a configured method (shows account name/number,
  instructions, Bangla QR image), amount + currency + transaction ID →
  `POST /wallets/manual-deposit`; "pending admin approval" result.
- **FR-605 Top-up result states.** Success / failed / cancelled with reason.

## H. Withdrawals
- **FR-701 Payout accounts.** List, add (bank/mobile), set default, delete (max 5).
- **FR-702 Withdrawal request.** Config + blockers, amount with fee/net preview,
  account, category, note.
- **FR-703 Withdrawal history.** Status chips, cancel while pending.
- **FR-704 Withdrawal receipt.** Reference, amounts, frozen rate, payout, account line; share.

## I. Referrals
- **FR-801 Refer & earn screen.** Eskimo "Free data" card pattern: code chip + Invite
  (share `share_url`), how it works (event amounts), stats (reward balance, total
  earned, people joined), referred people and rewards list.
- **FR-802 Claim a referrer.** Visible while `can_claim`; `POST /referrals/claim`.
- **FR-803 Referral pre-fill.** From `?ref=CODE` links; `GET /referrals/validate` shows
  "Invited by @user, you get X".

## J. Handset compatibility (requested feature)
- **FR-950 Detect handset eSIM support.** Native channel `co.triptel.app/esim`:
  Android `FEATURE_TELEPHONY_EUICC` + `EuiccManager.isEnabled()` (API 28+),
  brand/model; iOS `CTCellularPlanProvisioning.supportsEmbeddedSIM` (16+) /
  `supportsCellularPlan()`, machine identifier → marketing name map. Verdict:
  **supported / not supported / unknown** (unknown = old OS, API error, or feature
  present but disabled/locked). Decision logic in pure Dart, unit-tested.
- **FR-951 Compatibility result screen.** Eskimo pattern: result-tinted header
  (green / red / amber), device chip ("vivo V2344"), verdict, explanation, carrier-
  lock info box, "View supported devices".
- **FR-952 Supported devices list.** Curated list by brand (Apple · Samsung ·
  Google · Other) ported from web `guides/compatible-phones`, searchable; `*#06#`
  EID check tip; settings-path fallback per OS.
- **FR-953 Compatibility everywhere it matters.** Home promo card, Account → "Check
  device compatibility", checkout gate (FR-301), install gating (FR-404/FR-310).
  Cache the verdict per app session.

## K. Guides & help
- **FR-901 eSIM setup guide.** iOS/Android steps, install-once warning,
  troubleshooting checklist (port of web `guides/esim-setup-guide`).
- **FR-902 "New to eSIM?" sheet.** Short explainer + links to guide, compatibility, support.

## L. Account & KYC
- **FR-1001 Account screen.** Eskimo Account pattern: greeting card (name, wallet
  balance, reward credit), Invite CTA; groups **Account** (Profile, Identity
  verification status), **Settings** (Language, Currency), **Support** (Check device
  compatibility, Setup guide, Help/Support tickets, Track an eSIM), **About**
  (legal docs, version), Sign out.
- **FR-1002 Profile.** Avatar, name, username, email + verified badge, Google badge,
  phone edit (`PUT /auth/me/preferences`), change password.
- **FR-1003 KYC.** `GET /kyc/me` status (none/pending/approved/rejected+reason);
  submit NID number + front (required) + back photo.

## M. Support
- **FR-1101 Ticket list.** Reference, subject, status chip, last activity.
- **FR-1102 New ticket.** Category (no PARTNER), subject, body, optional eSIM link,
  up to 5 attachments ≤ 5 MB.
- **FR-1103 Ticket thread.** Messages (You/Support), attachments via authenticated
  download, reply with files, close, resolved banner.
- **FR-1104 Contact shortcuts.** WhatsApp / phone / email from public settings (hidden if null).

## N. Legal
- **FR-1201 Legal documents.** List + reader (markdown-lite).

## O. Real-time support chat — unblocked 2026-11-19
Was blocked on web shipping the chat backend first; all of it
(FR-C101–C107, FR-C201–C206, FR-C301/C302) is now built and confirmed
**genuinely live** on `beta.triptel.co` — not just "deployed," actually
proven end-to-end with a real connect + a real broadcast received by a
real second socket (see `D:\eSim\claude-progress.md`'s 2026-11-18
entries, especially "Real production bug" — the first live check found
WS connect/auth worked but broadcast delivery silently didn't, root-
caused to a datetime-serialization bug, fixed and reverified live
before this was called done). `docs/API.md`'s §12 WS section now
documents the real, exercised contract — read that before FR-C901,
not this paragraph. Replaces FR-1101–1103 above with a live version
(same `SupportTicket`/`SupportMessage` backend, not a new system).
- **FR-C901 WS client wiring.** `wss://.../ws/support/tickets/{id}?token=`,
  reconnect with backoff, falls back to the existing REST fetch while
  disconnected. See `D:\eSim\docs\Rules.md` — WS auth is `?token=`, never a
  header (mobile WS clients can set headers, but match the web contract
  exactly rather than diverging).
- **FR-C902 Live thread screen.** Avatars (`author_avatar_url`), typing
  indicator (animated dots, never persisted — matches web), auto-scroll.
- **FR-C903 Share an order or package.** Picker over the user's own
  `GET /orders/my-esims`-backed orders or the catalog; sends
  `shared_order_id`/`shared_product_id`; renders a rich card.
- **FR-C904 Home "Chat with Support" button.** Visible on Home (FR-201),
  opens FR-C902's thread (new ticket if none open).

## P. eSIM adapter — write a profile to a USB CCID reader (added 2026-11-19, awaiting go-ahead)
**Why:** a traveller whose phone has no eUICC (e.g. the vivo test device)
can still use a Triptel plan by writing the profile to a **removable eSIM
card inside a USB smart-card (CCID) reader/adapter**. The user asked for
two tiers from `docs/OpenEUICC_Reference.md`: the pure-Dart pieces and the
native USB + profile-download engine. Read that reference doc and
`DECISIONS.md`'s 2026-11-19 "eSIM adapter" entry before any FR here.

**The model is EasyEUICC (unprivileged), never OpenEUICC.** This app can't
manage the phone's *internal* eSIM (privileged permissions Google never
grants a normal app), so every FR below talks only to a chip behind a USB
CCID reader. **Android only**: iOS hides every entry point (no USB CCID
access for a third-party Flutter app). **No backend changes needed**: the
activation code comes from data this app already gets (`lpa_string`,
`smdp_address`, `matching_id`, API.md §7–8).

**Gates (all must be cleared by the user before the loop starts this
section; tracked as `blocked` in `feature_list.json`):**
1. **Go-ahead.** The user asked to review this scoping first.
2. **License (ask before deciding).** lpac isn't one license: its `src/`
   and `driver/` are **AGPL-3.0-only**; only its `euicc/` core library is
   **LGPL-2.1-only OR a commercial ESTKME license** (per lpac's
   `REUSE.toml`). The plan links **only `euicc/`** as a separate shared
   library, with this app's own APDU and HTTP drivers (no AGPL code). The
   user confirms this, or chooses the commercial license.
3. **Hardware** (FR-L910 onward): a CCID USB reader, a removable eUICC
   card (e.g. 9eSIM/eSTK.me class), and a test phone with USB host/OTG
   (`pm has-feature android.hardware.usb.host`). The phone is covered: the
   Pinehurst test device reports USB host = true (2026-11-19). Still needed:
   the reader and the card.
4. **Test profile** (FR-L917): a free/test activation code. Downloading a
   real Triptel order's profile uses up that code (real money), so it
   needs an explicit OK per CLAUDE.md.

### P1. Pure Dart, no native work, testable now
- **FR-L901 Activation-code parser.** Pure Dart `ActivationCode` value type
  + `parseActivationCode(String)` for SGP.22's
  `LPA:1$<smdp-address>$<matching-id>[$<smdp-oid>[$<conf-code-required>]]`
  (`$`-delimited; `1` = format version; empty matching ID allowed; flag
  `1` means a confirmation code is required). Also accepts the
  lowercase `lpa:` URI form, the string wrapped in a URL query parameter
  (e.g. Android's `esimsetup.android.com/...?carddata=<urlencoded>`),
  and surrounding whitespace. Returns a typed error (not a throw) for
  wrong prefix/version, a missing/invalid SM-DP+ host, or too many fields.
  `toLpaString()` round-trips. Also builds one from this app's own data
  (`lpa_string`, else `smdp_address` + `matching_id`). Unit tests only.
- **FR-L902 Activation-code input.** One screen, four sources, all feeding
  FR-L901's parser: (a) live QR camera scan, (b) decode a QR from a
  gallery image (existing `image_picker`), (c) paste from clipboard,
  (d) manual form (SM-DP+ address, matching ID, optional confirmation
  code). Shows a parsed, masked preview ("smdp.io · ABC…") and the
  "confirmation code required" hint. New dependency `mobile_scanner`
  (camera + image decode), pinned to a version supporting Flutter 3.27 /
  Dart 3.6 and recorded in DECISIONS.md. Camera permission denial is a
  normal state with a path to the other three sources. Widget tests with
  a faked scanner seam; device screenshot of the screen.

### P0. OMAPI removable-SE spike (added 2026-11-19, pivot — see DECISIONS.md)
- **FR-L905 OMAPI ARA-M access probe.** The user has a removable eUICC card
  already in a test phone's physical SIM tray (not a USB CCID reader) and
  asked to proceed on that path. §1.2 of `docs/OpenEUICC_Reference.md` is
  explicit that this only works if the *card's own* ARA-M access-control
  list grants *this app's* signing certificate hash — not something
  configurable from this repo, and not guessable without a real device.
  FR-L905 is the cheap, reversible way to get a real answer: a minimal
  Kotlin `OmapiProbe` (new `android.se.omapi.SEService` → list readers →
  the UICC reader → `openSession()` → `openLogicalChannel(ISD-R AID)`)
  behind a new MethodChannel `co.triptel.app/omapi`, with a tiny Dart
  diagnostic screen that shows the raw result (API available?, reader
  names, channel opened or denied, raw error). API 28+ only (guarded);
  below that, reports `omapi_requires_api28` rather than crashing. No
  permission needed beyond what OMAPI itself requires on stock Android.
  **This FR's own result decides what happens next**, not a judgment call:
  - **Channel opens** → the ARA-M allows us. FR-L910–L913 get rewritten
    from USB-CCID framing to OMAPI (`Reader`/`Session`/`Channel` replace
    `UsbManager`/`UsbDeviceConnection`; no CCID bulk-transfer protocol
    needed at all — OMAPI already speaks APDU). FR-L914 onward (lpac
    `euicc/`, profile list/download/manage) are transport-agnostic per
    the reference doc's §1.4 `EuiccChannel` abstraction and apply either
    way with no changes.
  - **`ara_m_denied`/`SecurityException`** → confirmed dead end for *this*
    card with *this* app's certificate. Falls back to the originally
    scoped USB-CCID path (gate 3: still needs an actual reader).
  - **No UICC reader / no SE present** → this phone+slot combination
    doesn't expose what was expected; report findings, no silent retry.
  Device evidence (the raw probe result, screenshotted) is the whole
  point of this FR — there's nothing to unit-test beyond the Dart
  result-parsing, which still gets a test with a faked channel.
  **Result, confirmed live 2026-11-19: `ara_m_denied`** (real
  `AccessControlException`, see DECISIONS.md) — the Pinehurst test
  phone's in-tray card's ARA-M does not list this app's certificate.
  The in-tray path is a confirmed dead end for this specific card; P2
  (USB-CCID) is the live path again, still gated on a real reader.
- **FR-L906 `lpa:` deep-link handoff.** No OMAPI/ARA-M access needed at
  all — SGP.22's `lpa:` scheme (FR-L901 §2.2, FR-L902) is a standard
  Android deep link; any LPA app (EasyEUICC, 9eSIM's NekokoLPA, JMP SIM
  Manager, …) can register as its handler, and does. Triptel can build
  the real activation-code URI from an order's own data
  (`buildActivationCodeFromOrderData` + `ActivationCode.toLpaString()`,
  both already built for FR-L901) and hand it to
  `Intent.ACTION_VIEW` via the existing `urlLauncherProvider` seam
  (same one FR-404's 1-tap install button already uses for
  `esimsetup.{apple,android}.com` links) — the already-installed,
  already-ARA-M-trusted app does the actual card write. One
  `AndroidManifest.xml` change: a `<queries>` entry for the `lpa`
  scheme (Android 11+ package-visibility rule — without it,
  `launchUrl`/`canLaunchUrl` can't see a real handler even when one is
  installed). No native Kotlin code, no NDK, no `lpac`, no license
  question. **Confirmed live 2026-11-19** that this device's resolver
  already points `lpa:` at an installed handler (`adb shell pm
  resolve-activity -a android.intent.action.VIEW -d
  'lpa:1$...'` → `isDefault=true`); both NekokoLPA and JMP SIM Manager
  independently opened the same real card through it (DECISIONS.md).
  On "My eSIM" detail (FR-404), a secondary button next to the 1-tap
  install button ("Install to a removable eSIM adapter" or similar);
  if `launchUrl` returns `false` (no handler installed), a clear
  message explains that an eSIM-manager app is needed, not a silent
  failure. This is a second, equally ARA-M-independent path alongside
  P2's native USB-CCID engine below — much less engineering, but
  depends on *some* compatible app being on the user's phone, and
  Triptel doesn't own the install UX once handed off. Both may ship;
  neither replaces the other. Widget tests with a faked
  `urlLauncherProvider` (no real Intent in tests, same pattern as
  FR-404's own install-button tests); device evidence on a real phone
  with a real handler installed.

### P2. Native engine (Android): USB CCID transport + profile operations
**Confirmed live (2026-11-19): FR-L905 came back `ara_m_denied`** — the
in-tray card doesn't grant this app access, so FR-L910–FR-L913 stay as
written below (USB CCID, not OMAPI) and remain gated on gate 3: an
actual USB CCID reader, which the Pinehurst test phone's SIM tray does
not substitute for.
- **FR-L910 Reader detection & hot-plug.** Kotlin in the app module:
  enumerate `UsbManager.deviceList`, keep devices with an interface of
  class `USB_CLASS_CSCID` (0x0B); register attach/detach receivers while
  the app is foregrounded (no manifest auto-launch). EventChannel
  `co.triptel.app/ccid/readers` streams `[{id, name, vendorId, productId,
  hasPermission}]`. Dart: `CcidReader` model, `ccidReadersProvider`
  (stream), empty/unsupported states (iOS, or no USB host feature).
  Dart tests via a faked channel; device evidence needs a real reader.
- **FR-L911 USB permission.** `requestPermission(device, PendingIntent)`
  with an app-private broadcast action; the Dart result is
  granted | denied | detached-meanwhile. A denial can be retried and
  never crashes.
- **FR-L912 CCID transceiver.** USB-CCID (rev 1.0) over bulk endpoints:
  `PC_to_RDR_IccPowerOn` (voltage fallback 5V → 3V → 1.8V),
  ISO/IEC 7816-3 ATR parsing, T=0/T=1 selection
  (`PC_to_RDR_SetParameters`), `PC_to_RDR_XfrBlock` with sequence
  numbers, slot-status/error mapping, and a TPDU-mode quirk list. All
  bulk I/O off the main thread. JVM unit tests on the framing and ATR
  parser with recorded byte transcripts (no hardware needed).
- **FR-L913 APDU layer.** `MANAGE CHANNEL` open/close, `SELECT` ISD-R by
  AID, Terminal Capabilities, response chaining (`61xx` → `GET
  RESPONSE`; `6Cxx` → resend with corrected Le). Exposed to the euicc
  library as its APDU interface (FR-L914). JVM unit tests with recorded
  transcripts.
- **FR-L914 euicc library integration.** Vendor lpac's `euicc/` (LGPL)
  under `third_party/lpac-euicc/` with its license files, build it with
  the NDK via **`ndk-build`** (`externalNativeBuild { ndkBuild {...} }`
  + a `.mk` file — not CMake; confirmed against a real, shipping
  reference implementation, `gitea.angry.im/jmp-sim/jmp-sim-manager`'s
  `libs/lpac-jni`, see DECISIONS.md's 2026-11-19 entry) as a separate
  shared library for `arm64-v8a`, `armeabi-v7a` and `x86_64`, and write
  the app's own JNI glue for **its own** APDU driver (→ FR-L913) and
  HTTPS driver (Kotlin `HttpsURLConnection`; TLS validated, no
  cleartext) — exactly that reference's own pattern: its `.mk` compiles
  only `euicc/*.c` + `cjson-ext/*.c` into the `.so`, never the AGPL
  `src/`/`driver/` files its submodule checkout also contains but never
  builds. No AGPL `src/` or `driver/` code here either. **The first
  step is a spike** that confirms the library's real driver-interface
  shape and API from its headers before any glue is written (that
  reference's `lpac-jni.c`/`lpac-jni.h` is a second, independent source
  to check the shape against, not just `euicc/`'s own headers). Done =
  a real EID read from a real card.
- **FR-L915 Adapter screen + chip info.** New screen (Account → "eSIM
  adapter (USB)", Android only): connected reader, permission CTA, EID
  (masked, tap to reveal/copy; never sent to any API), EuiccInfo2
  summary (free memory, SGP.22 version), with empty, error and
  "unplugged mid-read" states.
- **FR-L916 List profiles on the card.** ICCID (masked), provider,
  profile name/nickname, enabled/disabled, profile class. Refreshes
  after every mutation (FR-L917–L920).
- **FR-L917 Download a profile (SGP.22 ES9+).** Input = an
  `ActivationCode` from FR-L902, plus a confirmation code when the flag
  requires it. An explicit "This uses up the activation code" confirm
  step, then a progress screen driven by the library's download states,
  with the screen kept awake and a cancel option only before the
  point of no return. Failures go through a pure-Dart error-mapping table
  (raw SGP.22/library code → plain message; unknown codes fall back to a
  generic message + the raw code for support). IMEI is not sent. Tested
  with a faked engine; real-card evidence uses a test profile (gate 4).
- **FR-L918 Enable / disable a profile.** One enabled profile at a time,
  per SGP.22; disabling the active one asks for confirmation. Uses the
  library's refresh flag; the list re-reads afterwards.
- **FR-L919 Delete a profile.** Destructive and irreversible, so a typed
  confirmation; an enabled profile has to be disabled first (or the
  library's own error is shown verbatim through the mapping table).
- **FR-L920 Nickname a profile.** Local on-card metadata only, length-
  validated; never sent to Triptel.
- **FR-L921 SGP.22 notifications.** List pending notifications (seq
  number, operation, SM-DP+), send one or all, discard with confirmation.
  Auto-send right after FR-L917–L919 operations when online; queue
  otherwise and show a badge on the adapter screen. Required for spec
  correctness: carriers use them to confirm provisioning.
- **FR-L922 Triptel integration.** On My eSIM detail (FR-403/404), an
  "Install to USB adapter" action appears only when a reader is
  connected and the eSIM's lifecycle allows install (Rules.md: not
  SUSPENDED/REVOKED/CANCELLED/EXPIRED). It pre-fills FR-L917 with that
  eSIM's real activation code (FR-L901's builder) and the same
  use-it-up confirmation.

**Out of scope for P (documented so it isn't re-proposed):** the phone's
internal eSIM (OMAPI, privileged); removable eSIMs in the phone's own SIM
tray (only works if the chip vendor allowlists this app's certificate —
not plannable); registering as Android's `EUICC_UI`/`EuiccService`;
multiple chips/ISD-Rs at once; eUICC memory reset (destructive, test-lab
only); iOS; the `lpa:` deep-link handler (Android's own LPA owns that
scheme).

---

## Traceability: web customer routes → FRs (nothing left out)
| Web route / component | FRs |
|---|---|
| `/` (home, search, popular) | FR-201, FR-202 |
| `/destinations` | FR-202, FR-203 |
| `/explore/[slug]` + `PackageBrowser` (fixed/day-pass tabs, filters, discount box) | FR-204, FR-205, FR-206, FR-301–FR-311 |
| `PaymentMethodChooser` | FR-305, FR-408 |
| `/auth/login`, `/register`, `/forgot-password`, `/reset-password`, `/set-password` | FR-101–FR-107 |
| `/my-esims`, `/my-esims/[id]`, `EsimLiveStatus`, `TopupPanel`, `EsimQr` | FR-401–FR-410 |
| `/my-esims/[id]/print` | FR-409 |
| `/track/[token]` | FR-501 |
| `/wallet` (balances, ledger, top-up, manual deposit) | FR-601–FR-605 |
| `/wallet/withdraw`, `/wallet/withdraw/[id]` | FR-701–FR-704 |
| `/refer` | FR-801, FR-802 |
| `/profile` (+ KYC) | FR-1001–FR-1003 |
| `/support`, `/support/[id]` | FR-1101–FR-1104 |
| `/guides/compatible-phones` | FR-950–FR-953 |
| `/guides/esim-setup-guide` | FR-901 |
| `/legal/[slug]` | FR-1201 |
| `MaintenanceGate`, currency/language switchers | FR-003, FR-005, FR-006 |
| `/partners`, `/reseller`, `/agent`, `/admin`, `/api-docs` | **Out of scope** |
| *(no web equivalent: app-only, Android-only)* eSIM adapter / USB CCID | FR-L901–FR-L922 (§P) |

## Explicitly out of scope
Merchant "buy for a customer" (`is_buy_for_user`), merchant/agent applications,
COMMISSION transfers, partner API, admin tools, push notifications (no backend).
