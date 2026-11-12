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

## Explicitly out of scope
Merchant "buy for a customer" (`is_buy_for_user`), merchant/agent applications,
COMMISSION transfers, partner API, admin tools, push notifications (no backend).
