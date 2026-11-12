# Triptel User API — Mobile Reference (beta)
**Read when:** writing any API call, model class, or error handling.

Verified 2026-11-12 against the **live beta OpenAPI spec**
(`https://beta.triptel.co/openapi.json`) and the backend source in
`D:\eSim\backend\app\api\v1\*`. If this doc and the running backend disagree, the
backend wins — fix this doc in the same commit, and note it in `claude-progress.md`.

Scope: **customer (USER role) endpoints only.** Admin, merchant, agent, partner,
finance, `reseller-orders`, `apply-merchant`, support staff queue and the supplier
webhook exist but are **out of scope** for this app (see `docs/Rules.md`).

---

## 0. Conventions

| Item | Value |
|---|---|
| Base URL (beta, the only one this app uses) | `https://beta.triptel.co/api/v1` |
| Host for relative asset paths | `https://beta.triptel.co` (logos, uploads, support attachments come back as `/api/v1/...` paths) |
| Health | `GET https://beta.triptel.co/health` |
| Auth header | `Authorization: Bearer <access_token>` |
| Token lifetime | 7 days. **No refresh endpoint.** On `401` clear the session → login |
| Content type | JSON, except KYC + support (multipart/form-data) |
| Money | Strings like `"2.1000"`. Treat **every amount as EUR** (see §0.2). Parse with a decimal type, never `double` for arithmetic |
| Dates | ISO-8601. Some are naive (no `Z`); treat naive as UTC |
| IDs | UUID strings (countries use integer `id`) |
| Errors | `{"detail": "<human message>"}` for 4xx; `422` = `{"detail":[{"loc":[...],"msg":"...","type":"..."}]}` |
| Rate limits | `429` (slowapi). Limits noted per endpoint |

Configure the base URL through `--dart-define=API_BASE_URL=...` (default to beta).
Never hardcode it in a screen.

### 0.1 Error codes that change app flow
| Status | `detail` | App behaviour |
|---|---|---|
| 401 | `Could not validate authentication credentials` | Clear token, go to Login, keep the route to resume |
| 403 | `Account suspended` | Sign out, show a suspended screen with Support contact |
| 403 | `Please set your own password before buying or moving money.` | Route to Set Password (FR-105). Returned by every `require_password_changed` endpoint |
| 404 | `eSIM not found` / `Ticket not found` / ... | Same 404 for "doesn't exist" and "not yours" by design — show "not found" |
| 429 | rate limited | Show "Too many attempts, wait a minute" — never auto-retry in a loop |

### 0.2 Currency — KNOWN BACKEND INCONSISTENCY
The platform base currency is **EUR** (`settings.BASE_CURRENCY`). Wallets, ledger,
orders, discounts, referral rewards and withdrawal limits are EUR.

**But** `ProductResponse.currency` reads `"USD"` for eSIM Access products
(`catalog_parsing.py:235`), while checkout debits `retail_price` 1:1 from the EUR
wallet and converts it to BDT as EUR. So the number is charged as EUR regardless of
the label. **Rule for the app: ignore `product.currency`; treat `retail_price` as EUR,**
exactly like the web storefront's `formatPrice()` does. (Flagged to the backend owner
— see `DECISIONS.md`. If the backend starts converting, this rule still holds because
the backend will then store EUR.)

Display conversion: `amount_eur * rate_to_base` from `GET /settings/rates`
(rates are "units per 1 EUR"). Zero-decimal currencies (JPY) render with 0 decimals.

---

## 1. App bootstrap (public)

### `GET /settings/public` → `PublicSettingsResponse`
Call on launch; cache. Real beta response:
```json
{
  "platform_name": "Triptel",
  "tagline_en": "Instant Global eSIM Data in 200+ Destinations",
  "tagline_bn": "২০০+ দেশে ...",
  "logo_light": "/api/v1/uploads/branding/logo_light-....png",
  "logo_dark": "/api/v1/uploads/branding/logo_dark-....png",
  "favicon": "/api/v1/uploads/branding/favicon-....png",
  "support_phone": "+8801979891996",
  "support_email": "support@triptel.co",
  "support_whatsapp": "+8801979891996",
  "default_currency": "EUR",
  "maintenance_mode": false,
  "social_links": {},
  "seo_title": "...", "seo_description": "...", "og_image": "/api/v1/uploads/...",
  "bangla_qr_image": "/api/v1/uploads/branding/bangla_qr_image-....png",
  "payment_methods": [
    {"id": "...", "name": "bKash Account", "kind": "mobile", "account_name": "...",
     "account_number": "...", "branch": null, "instructions": "...", "is_active": true}
  ],
  "topup_min": "0.01",
  "topup_max": "2000.00",
  "google_client_id": "1095507553767-hkuh44db04q1lvrnptill6frtckcb42t.apps.googleusercontent.com"
}
```
- `maintenance_mode: true` → blocking maintenance screen (FR-1203).
- Any contact field may be `null` → hide that contact, never invent one.
- `payment_methods` = manual-deposit destinations (only active ones are returned).
- `topup_min/max` are **EUR**.

### `GET /settings/rates` → `CurrencyRateResponse[]`
```json
[{"currency_code":"BDT","rate_to_base":"141.656046","is_manual_override":false,"manual_rate":null,"source":"..."}]
```
Beta currencies: AED, INR, JPY, MYR, SAR, SGD, THB, USD, BDT, EUR, GBP.
Use `manual_rate` when `is_manual_override` is true, else `rate_to_base`.

### `GET /settings/languages` → `LanguageResponse[]`
`{code, name, native_name, flag_emoji, is_active, is_rtl}`. Beta: en, bn, ar (RTL),
es, fr, de, zh, ja, ru, hi, tr, pt, it.

### `GET /settings/translations/{language_code}` → `{language_code, namespaces: {ns: {key: value}}}`
Missing keys are already back-filled with English server-side.

### `GET /settings/legal` → `[{slug, title, updated_at}]`
### `GET /settings/legal/{slug}` → `{slug, title, body, updated_at}`
`body` is admin-edited markdown-lite. 404 `Document not found`.

---

## 2. Auth

### `POST /auth/register` (5/min) → `Token`
```json
{"email":"a@b.co","username":"alice","password":"min8chars","phone":null,"full_name":null,"referral_code":"ABC123"}
```
- `400 Email or username already exists`.
- Unknown `referral_code` is **silently ignored** (never blocks sign-up).
- Password length isn't validated here (only on change/reset) — enforce ≥ 8 client-side.

`Token`:
```json
{"access_token":"...","token_type":"bearer","role":"USER","user_id":"uuid","username":"alice","must_change_password":false}
```

### `POST /auth/login` (10/min) → `Token`
`{"email": "<email OR username>", "password": "..."}` — the `email` field accepts a
username too. `401 Invalid email/username or password`, `403 Account suspended`.

### `POST /auth/google` (20/min) → `Token`
`{"credential": "<Google ID token>"}`. Server verifies `aud` against the **web** client
ID returned in `/settings/public.google_client_id`. On Android/iOS request the ID
token with that value as `serverClientId`, otherwise verification fails.
Errors: `401` could not verify · `400` Google email unverified · `409` email linked
to a different Google account · `503` unavailable.
Google sign-ups carry no referral → offer FR-802 (claim) afterwards.

### `GET /auth/me` (auth)
```json
{
  "id":"uuid","email":"...","username":"...","role":"USER","status":"ACTIVE",
  "phone":null,"full_name":null,"is_kyc_verified":false,
  "preferred_currency":"EUR","avatar_url":null,"email_verified":false,"has_google":false,
  "wallets":[{"type":"DEFAULT","wallet_type":"DEFAULT","balance":0.0,"currency":"EUR"}],
  "merchant_profile":null,"agent_profile":null
}
```
- **Does NOT return `must_change_password`.** Only the `Token` responses do. Persist
  the flag from login/register in secure storage, and also treat the 403 in §0.1 as
  the source of truth.
- `wallets[].balance` here is a float; prefer `/wallets/my-wallets` (string).
- Ignore `merchant_profile`/`agent_profile` (out of scope).

### `PUT /auth/me/preferences` (auth)
`{"preferred_currency":"BDT"}` and/or `{"phone":"+880..."}` (`""` clears phone).
→ `{"status":"success","preferred_currency":"BDT","phone":"..."}`.
`400 XXX isn't a currency we hold a rate for`.

### `POST /auth/change-password` (auth, 10/min)
`{"current_password":"...","new_password":"..."}` → `{"status":"success","message":"Password updated."}`.
Clears `must_change_password`. 400s: wrong current password · `< 8` chars · same as current.

### `POST /auth/forgot-password` (5/min)
`{"email":"..."}` → always the same generic success (no enumeration).
### `POST /auth/reset-password` (10/min)
`{"token":"...","new_password":"..."}`. Token comes from the emailed link, which
points to the **web** (`/auth/reset-password?token=`). 400: invalid/used/expired/short.

---

## 3. Catalog (public)

### `GET /catalog/countries?search=&popular_only=false` → `CountryResponse[]`
Only countries with at least one active, visible product. Sorted by name
(popular: by `popular_order`).
```json
{"id":107,"iso2":"JP","iso3":"JPN","name_en":"Japan","name_bn":null,
 "flag_url":"https://flagcdn.com/w80/jp.png","region":null,"is_popular":true,
 "popular_order":2,"is_active":true,"slug":"japan"}
```
**Regional / multi-country packages are pseudo-countries** (beta: 244 rows =
202 countries + 42 with `region == "Regional"`), e.g.
`{"iso2":"AUKUS-3","name_en":"AUKUS(3 countries)","region":"Regional","flag_url":null,"slug":"aukus-3-countries"}`.
- Country tab = `region != "Regional"`; Regional tab = `region == "Regional"` (Eskimo
  Country/Regional toggle maps 1:1). `flag_url` is `null` for regionals → globe icon.
- A regional that *includes* China (e.g. "China (mainland HK Macao)") is **not**
  listed on China's page — by design.
- `search` matches `name_en` or `iso2` (ILIKE).

### `GET /catalog/destinations/{slug}` → `{country: CountryResponse, products: ProductResponse[]}`
`slug` = name slug (`japan`) **or** ISO2 (`jp`). 404 `Country not found`.

### `GET /catalog/countries/{iso2}/products` → `ProductResponse[]`
### `GET /catalog/products/{product_id}` → `ProductResponse`
Products are ordered: featured first, then price ascending, then data ascending.
```json
{"id":"uuid","country_id":107,"title_en":"Japan 1GB 7Days","title_bn":null,
 "data_amount_gb":"1.00","validity_days":7,"retail_price":"2.1000","currency":"USD",
 "is_unlimited":false,"is_active":true,"is_featured":false,
 "coverage_networks":"HK","supplier_period_num":null,"coverage_countries":null}
```
Plan shapes (all three exist on beta Japan, 75 products):
| Shape | How to detect | Data label |
|---|---|---|
| Fixed data | `supplier_period_num == null && !is_unlimited` | `"{data_amount_gb} GB"` (0.10 → "100 MB") |
| Day Pass | `supplier_period_num != null` | `data_amount_gb` is the **total over all days** → show `data_amount_gb / validity_days` + `" GB/day"` |
| Unlimited | `is_unlimited == true` (`data_amount_gb` = "0.00") | `"Unlimited"` |

- `coverage_countries` is a list of country names for regional products, else `null`.
- `coverage_networks`: for eSIM Access products this currently holds the IP-export
  region (e.g. `"HK"`), **not** carrier names — don't render it as "Network".
- Several products can share data+validity (e.g. "Japan 1GB 7Days" vs "(IIJ)" vs
  "(nonhkip)") — show `title_en` to disambiguate.

---

## 4. Discounts

### `POST /discounts/check` (public) — pre-login estimate
`{"code":"WELCOME"}` →
```json
{"valid":true,"code":"WELCOME","description":"...","discount_type":"PERCENT","value":"10",
 "max_discount_amount":"5.00","scoped":false}
```
or `{"valid":false,"reason":"That code has expired."}` (always 200).
`scoped:true` → say "exact saving confirmed when you sign in". Estimate:
PERCENT → `min(price*value/100, max_discount_amount, price)`; else `min(value, price)`.

### `POST /discounts/preview` (auth) — authoritative per product
`{"code":"WELCOME","product_id":"uuid"}` →
```json
{"valid":true,"code":"WELCOME","description":"...","discount_type":"PERCENT","value":"10",
 "discount_amount":"0.21","list_price":"2.1000","total":"1.8900","currency":"EUR"}
```
or `{"valid":false,"reason":"..."}`. `404 Product not found or inactive`.

---

## 5. Wallets

### `GET /wallets/my-wallets` (auth) → `WalletResponse[]`
`{"id","wallet_type":"DEFAULT|REWARD|COMMISSION","balance":"12.5000","currency":"EUR","is_frozen":false}`
- **Spendable at checkout = DEFAULT + REWARD** (reward spent first).
- REWARD is never withdrawable. COMMISSION is merchant/agent — show only if > 0.
- Order is not guaranteed — select by `wallet_type`.

### `GET /wallets/ledger?limit=50&wallet_type=` (auth) → `LedgerEntryResponse[]`
`{"id","tx_type":"CREDIT|DEBIT","amount","balance_before","balance_after","reference_type","description","created_at"}`
`reference_type`: DEPOSIT_GATEWAY, DEPOSIT_MANUAL, ORDER_PURCHASE, COMMISSION_EARNED,
ADMIN_ADJUSTMENT, REFUND, COMMISSION_TRANSFER, WITHDRAWAL_HOLD, WITHDRAWAL_REVERSED,
REWARD_EARNED, REWARD_REVERSED, AGENT_COMMISSION_EARNED, ESIM_TOPUP_PURCHASE.

### `POST /wallets/manual-deposit` (auth) → `ManualDepositResponse`
`{"amount":"1000","currency":"BDT","bank_name":"bKash Account","transaction_id":"TX123","receipt_url":null}`
- `bank_name` must equal one of `/settings/public.payment_methods[].name`.
- `currency` defaults BDT; must be a supported rate.
- Response `{"id","amount","currency","bank_name","transaction_id","status":"PENDING","created_at"}`.
- There is no customer upload endpoint for a receipt image — leave `receipt_url` null.
- **No endpoint lists my past manual deposits** — show the submission result only;
  credited deposits appear in the ledger as `DEPOSIT_MANUAL`.

### `POST /payments/shurjopay/topup?amount=500&currency=BDT` (auth, password-changed)
Query params, empty body. `amount` in `currency` (default EUR); limits checked in EUR.
→ ShurjoPay payload incl. `checkout_url` (also try `checkoutUrl`).
400s: unsupported currency · `<= 0` · outside `topup_min..topup_max EUR` · gateway gave no link.
⚠️ **Return goes to the web**, not the app: the callback redirects to
`https://triptel.co/wallet?topup=success|failed&reason=` (see §9).

---

## 6. Orders & checkout

### `POST /orders/checkout` (auth, password-changed) — **wallet only**, 202
`OrderCreateRequest`:
```json
{"product_id":"uuid","payment_method":"WALLET","discount_code":null}
```
Never send `is_buy_for_user`, `beneficiary_*`, `auto_create_user` (merchant-only →
403). → `OrderResponse` with `status:"PROCESSING"`, `esim_profile:null`.
400s: `Use POST /payments/shurjopay/order-initiate for gateway checkout` (non-wallet
method) · discount error text · `This wallet is frozen...` · `Insufficient wallet balance. Please top up.`
404 `Product not found or inactive`.

Provisioning runs in the background (10–30 s, sometimes longer). **Poll**
`GET /orders/{id}`: every 2 s for ~12 s, then every 5 s up to ~170 s. Stop on
`COMPLETED` (eSIM ready) or `FAILED`. Anything else, including timeout, = "Setting up
your eSIM" — **never a failure** (backend auto-refunds real failures to the wallet and
emails the eSIM when ready).

### `GET /orders/{order_id}` (auth) → `OrderResponse`
```json
{"id","order_no":"ORD-20261112-AB12CD","buyer_id","beneficiary_id","product_id",
 "total_amount":"1.8900","discount_amount":"0.2100","currency":"USD","payment_method":"WALLET",
 "status":"PENDING|PAID|PROCESSING|COMPLETED|FAILED|CANCELLED","created_at",
 "esim_profile":{"id","order_id","iccid","lpa_string","qr_code_data","smdp_address",
                 "status":"ALLOCATED|RELEASED|INSTALLED|ACTIVE|EXPIRED|SUSPENDED|REVOKED|CANCELLED",
                 "is_mock_fallback":false,"created_at"} }
```
`order.currency` mirrors the product label — treat `total_amount` as EUR (§0.2).

### `POST /payments/shurjopay/order-initiate` (auth, password-changed)
Body = `OrderCreateRequest` with **`"mobile": true`**:
```json
{"product_id":"uuid","payment_method":"SHURJOPAY","discount_code":"WELCOME","mobile":true}
```
→ ShurjoPay payload + `"order_id"`, `"order_no"`. Open `checkout_url` (§9). Order is
`PENDING` until the callback confirms payment, then `PROCESSING` → poll as above.
502 `Could not start ShurjoPay checkout: ...` (no order left behind).

### `GET /orders/my-esims` (auth) → list (newest first)
Every profile where I'm buyer **or** beneficiary:
```json
{"id":"<esim profile id>","order_no","product_title","data_amount_gb":1.0,"is_unlimited":false,
 "validity_days":7,"iccid","lpa_string","qr_code_data","smdp_address",
 "status":"ALLOCATED","is_mock_fallback":false,"created_at",
 "activated_at":null,"expires_at":null,"is_beneficiary":true}
```
- Orders still provisioning (no profile yet) are **not** in this list.
- `data_amount_gb/validity_days` are the **original purchase** — after a top-up they
  are stale. Use `/esims/{id}/status` for real totals.
- `activated_at/expires_at` stay null until installed: say "Validity starts on install".
- No `share_token` here — get `share_url` from the status endpoint.

---

## 7. eSIM status, tracking & top-up

### `GET /esims/{esim_id}/status` (auth)
Cached 5 min server-side; never fails because the supplier is down (returns last
snapshot + error).
```json
{
  "esim_id":"uuid","order_no":"ORD-...","purchased_at":"...",
  "product":{"title":"Japan 1GB 7Days","validity_days":7,"is_unlimited":false,"data_amount_gb":"1.00"},
  "iccid":"8985...","lpa_string":"LPA:1$smdp.io$ABC","qr_code_data":"LPA:1$...",
  "smdp_address":"smdp.io","matching_id":"ABC","supplier_reference":"<supplier txn id>",
  "supplier":"esimaccess|vivape","esim_status":"ALLOCATED",
  "status":{"label":"Not installed yet","code":0,"is_installed":false,"is_activated":false,"device_model":null},
  "usage":{"used_mb":"0","used_bytes":0,"formatted":"0.00 MB","allowance_mb":"3072.00",
           "remaining_mb":"3072.00","remaining_formatted":"3.00 GB","used_pct":0.0,"is_unlimited":false},
  "validity":{"days":21,"activated_at":null,"expires_at":null,
              "note":"Validity starts when you install this eSIM — 21 days from then."},
  "share_url":"https://triptel.co/track/<token>",
  "history":[], "daily_breakdown":[],
  "telemetry":{"fetched_at":"...","error":null,"available":true}
}
```
- **Use `usage.allowance_mb` and `validity.days` — they include top-ups.**
  `product.*` is the original plan.
- Unlimited: `allowance_mb`/`remaining_mb`/`used_pct` are `null` — no progress bar.
- `esim_status` drives actions: `SUSPENDED`/`REVOKED`/`CANCELLED`/`EXPIRED` → no
  install button, no top-up, show a status banner.
- `status.device_model`: only VivaPe supplies it; eSIM Access → always `null`.
- `history[]` (VivaPe only) items may contain `eid`; `daily_breakdown[]` VivaPe only.
- `telemetry.error` non-null → show "Live usage temporarily unavailable" + `fetched_at`.
- `share_url` points to the **web** tracking page.

### `POST /esims/{esim_id}/refresh` (auth, 20/min) — same shape, forces a re-fetch
Server also enforces a per-eSIM cooldown; disable the button for ~30 s after use.

### `GET /esims/public/{token}` (public, 60/min) — same shape, `share_url:null`, no EIDs
404 `Not found` for unknown/short tokens. Token = last path segment of a
`https://triptel.co/track/<token>` link.

### `GET /esims/{esim_id}/topup-options` (auth) → `TopupOptionResponse[]`
`{"package_code","title","data_amount_gb":"1.00","validity_days":7,"retail_price":"2.10","currency":"..."}`
Live from the supplier, never cached. **Empty list = top-up not available** (any
non-eSIM-Access eSIM, or not delivered) → hide the section entirely.

### `POST /esims/{esim_id}/topup` (auth, 10/min) — pay from wallet → `EsimTopupResponse`
`{"package_code":"..."}` →
`{"id","esim_profile_id","package_code","title","data_amount_gb","validity_days","retail_price","currency","status":"PENDING|COMPLETED|FAILED","created_at","completed_at"}`
Synchronous. 400 with message for unavailable package / insufficient balance. On a
supplier failure the debit is refunded and status `FAILED`.

### `POST /payments/shurjopay/esim-topup-initiate?esim_id=<uuid>` (auth, password-changed)
Body `{"package_code":"..."}` → ShurjoPay payload + `"topup_id"`.
⚠️ Return goes to the **web**: `https://triptel.co/my-esims/{esim_id}?topup=success|failed`.
After the user returns, re-load `/esims/{id}/status` (allowance grows on success).

**Top-up payment choice** (same as first purchase): if DEFAULT+REWARD ≥ price → offer
Wallet vs ShurjoPay; else go straight to ShurjoPay.

### Install links (client-side, from `lpa_string`)
```
iOS 17.4+ : https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=<urlencoded LPA>
Android   : https://esimsetup.android.com/esim_qrcode_provisioning?carddata=<urlencoded LPA>
```
Only when `lpa_string` starts with `LPA:`. Manual fallback: SM-DP+ address +
matching ID (copyable). QR = `qr_code_data` (or `lpa_string`).

---

## 8. Referrals

### `GET /referrals/validate?code=ABC` (public)
→ `{"valid":true,"referrer_username":"bob","joining_reward":"1.00","currency":"EUR"}` or `{"valid":false}`.
### `GET /referrals/me` (auth)
```json
{"code":"ALICE12","is_enabled":true,
 "events":{"JOINING":{"referrer":"1.00","referred":"1.00","enabled":true},
           "FIRST_PURCHASE":{...},"NEW_MERCHANT":{...}},
 "promo_balance":"2.00","total_earned":"3.00","referred_count":2,
 "referred":[{"username":"carol","joined_at":"...","role":"USER"}],
 "rewards":[{"event":"JOINING","referred_username":"carol","amount":"1.00","status":"GRANTED","created_at":"..."}],
 "currency":"EUR","share_url":"https://triptel.co/auth/register?ref=ALICE12",
 "can_claim":true,"referred_by":null}
```
Hide NEW_MERCHANT in this app (merchant feature). `is_enabled:false` → hide the programme.
### `POST /referrals/claim` (auth) `{"code":"BOB123"}` (3–16 chars)
→ same summary with `can_claim:false`. 400: already has a referrer · invalid · self · after first completed purchase.

---

## 9. ShurjoPay hand-off (all gateway flows)
The backend gives a `checkout_url`; ShurjoPay returns to the backend
`GET /payments/shurjopay/callback?order_id=...`, which then **redirects**:

| Flow | Initiated by | Final redirect |
|---|---|---|
| eSIM purchase | `order-initiate` with `mobile:true` | `triptel://payment-callback?order=<order_id>` or `triptel://payment-callback?payment=failed&reason=<r>` |
| Wallet top-up | `shurjopay/topup` | `https://triptel.co/wallet?topup=success` / `?topup=failed&reason=` |
| eSIM top-up | `esim-topup-initiate` | `https://triptel.co/my-esims/<id>?topup=success|failed` |

Open checkout in an in-app **WebView** and intercept navigation: stop on any
`triptel://` URL, or on a URL starting with `https://triptel.co/wallet` /
`https://triptel.co/my-esims` (beta's `FRONTEND_BASE_URL` may be `https://beta.triptel.co`
— match both hosts). Parse the query, close the WebView, then **re-read server state**
(order poll / wallets / eSIM status) — the redirect query is a hint, not proof.
Also let `intent://`/bKash/Nagad app links open externally. Backend gap (logged):
wallet and eSIM top-ups have no `-M-` mobile variant yet.

---

## 10. Withdrawals (KYC-gated)

### `GET /withdrawals/config` (auth)
```json
{"min_amount":"5","max_amount":"500","fee_type":"PERCENT|FLAT","fee_value":"1.5",
 "payout_currency":"BDT","processing_time":"1-3 business days","is_enabled":true,
 "base_currency":"EUR","note_categories":["withdrawal","commission","refund","renew","business","other"],
 "balance":"12.00","can_withdraw":false,"blockers":["..."],"kyc_verified":false,
 "kyc_status":null,"account_count":0}
```
Show `blockers` verbatim; if KYC is a blocker offer "Verify now" (FR-1002).
### Payout accounts
- `GET /withdrawals/accounts` → `[{"id","account_type":"BANK|MOBILE","bank_name","holder_name","account_number","branch_name","routing_number","is_default"}]`
- `POST /withdrawals/accounts` `{"account_type":"MOBILE","bank_name":"bKash","holder_name":"Alice","account_number":"017...","branch_name":null,"routing_number":null,"is_default":false}` (bank_name 2–120, holder 2–160, number 4–64). Max 5; duplicate → 400. First account becomes default.
- `POST /withdrawals/accounts/{id}/default` → `{"status":"success"}`
- `DELETE /withdrawals/accounts/{id}` → `{"status":"success"}`; 400 if a pending withdrawal uses it.
### Requests
- `GET /withdrawals?limit=50`, `GET /withdrawals/{id}`, `POST /withdrawals/{id}/cancel` (pending only)
- `POST /withdrawals` (password-changed) `{"amount":"10","bank_account_id":"uuid","note_category":"withdrawal","note":"..."}` (note ≤ 500)

Withdrawal object:
```json
{"id","reference_no","amount","fee_amount","net_amount","note_category","note",
 "account":{...snapshot},"account_line":"bKash · 017… · Alice","status":"PENDING|PAID|REJECTED|CANCELLED",
 "payout_currency":"BDT","conversion_rate":null,"payout_amount":null,"payment_reference":null,
 "has_proof":false,"rejection_reason":null,"reviewed_at":null,"created_at"}
```
`amount/fee/net` are EUR; `payout_amount` is in `payout_currency`, frozen at approval.

---

## 11. KYC

- `GET /kyc/me` → `{"submitted":false,"status":null}` or `{"submitted":true,"status":"PENDING|APPROVED|REJECTED","rejection_reason":null,"submitted_at":"..."}`
- `POST /kyc/submit` multipart: `nid_number` (text), `document_front` (file, required), `document_back` (file, optional). PNG/JPEG/WEBP/PDF, ≤ 5 MB each. Resubmitting resets to PENDING. → `{"status":"success","submission_status":"PENDING"}`

---

## 12. Support

- `GET /support/categories` (public) → `[{"value":"ESIM","label":"eSIM not working"},{"value":"PAYMENT",...},{"value":"REFUND"},{"value":"ACCOUNT"},{"value":"PARTNER"},{"value":"OTHER"}]` — hide PARTNER in this app.
- `GET /support/tickets` → up to 100, newest activity first:
  `{"id","reference","subject","category","status","order_id","created_at","last_message_at","resolved_at","closed_at"}`
- `POST /support/tickets` multipart: `subject`, `body` (≤ 5000), `category` (default OTHER), `order_id` (optional, link an eSIM's order), `files` (repeatable, ≤ 5, ≤ 5 MB each; png/jpeg/webp/heic/pdf/txt) → ticket + `messages`
- `GET /support/tickets/{id}` → ticket + `messages:[{"id","body","is_staff","author":"You|Support","created_at","attachments":[{"id","name","content_type","size_bytes","url":"/api/v1/support/attachments/<id>"}]}]`
- `POST /support/tickets/{id}/messages` multipart `body`, `files` → updated ticket. Replying to a resolved ticket reopens it; a CLOSED ticket rejects replies (400).
- `POST /support/tickets/{id}/close`
- `GET /support/attachments/{id}` (auth) → file bytes. Download with the Bearer header (image widgets can't add it by themselves).

---

## 13. Endpoints that do NOT exist (don't build against them)
- Refresh token, logout (logout = delete local token).
- Push-notification device registration (all notifications are email).
- Order history list (only `my-esims` + single order).
- List of my manual deposits; receipt upload.
- Handset/device-compatibility API — compatibility is detected **on the device**
  (see `docs/Functional_Requirements.md` FR-950..953) plus a curated list in the app.
- Account deletion endpoint (store policies require one — logged as backend gap).

## 14. Changes since the React Native app's docs (eSIM Access era)
- `ESIMStatus` gained `SUSPENDED`, `REVOKED`, `CANCELLED`.
- Status response gained `supplier`, `esim_status`; totals now include top-ups.
- New: top-up options / wallet top-up / gateway top-up endpoints.
- Products: Day Pass (`supplier_period_num`), unlimited fixed plans, regional
  pseudo-countries with `coverage_countries`, `region == "Regional"`.
- eSIM Access products are labelled `USD` (§0.2).
