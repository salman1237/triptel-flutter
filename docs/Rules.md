# Rules
**Read when:** writing any code. Each rule comes from a real incident in the web
app, the RN app, or a backend guarantee. Don't relax one without reading why.

## Scope
- Customer app only. Never call `/admin/*`, `/merchant/*`, `/agent/*`, `/partner/*`,
  `/finance/*`, `/orders/reseller-orders`, `/auth/apply-merchant`, support staff
  endpoints, or send `is_buy_for_user`/`beneficiary_*`/`auto_create_user`.
- Beta API only (`API_BASE_URL`, default beta). Never point a dev build at production.

## Auth
- JWT and `must_change_password` live in `flutter_secure_storage` only. Never in
  SharedPreferences, logs, crash reports, or widget state outside the auth provider.
- Only the shared `ApiClient` adds `Authorization`. No ad-hoc headers in features.
- No refresh token exists: on 401 clear the session and route to login.
- The 403 "Please set your own password…" always routes to Set Password.

## Checkout & payment
- `PROCESSING`, `PENDING`, an empty poll or a poll timeout is **not a failure**.
  Only `status == FAILED` shows an error. (The web once refunded orders that were
  still provisioning.)
- Never compute the charged amount on device. `/discounts/check` is an estimate;
  `/discounts/preview` + the server checkout are authoritative.
- Wallet-vs-gateway is a UX choice; the backend decides if the wallet covers it.
- Gateway redirects are hints: after any return, re-read the order / wallets / status.
- Always send `mobile: true` to `order-initiate`.

## Money
- Every API amount is EUR, including products labelled `"USD"` (API.md §0.2).
- Parse money as decimal/cents, never accumulate `double`s.
- Display conversion only; converted values are never stored as truth.

## eSIM data
- Totals come from `/esims/{id}/status` (`usage.allowance_mb`, `validity.days`),
  not `my-esims`/`product` (stale after top-up).
- Unlimited plans have no allowance: no progress bar, no "remaining".
- Day Pass: show per-day data (`data_amount_gb / validity_days`), never the total.
- Treat only telemetry `is_installed` as installed; never infer from timestamps.
- Lifecycle `SUSPENDED|REVOKED|CANCELLED|EXPIRED` disables install and top-up.

## QR code
- Error correction **H**, logo **22 %** of QR width, white circular disc behind the
  logo, app mark not wordmark. Any change needs a damage test (decode after crop/noise).

## Compatibility
- Detection never hard-blocks a purchase (users buy for a future phone). It gates
  1-tap install buttons and shows guidance.
- "Unknown" is not "not supported": say "We couldn't confirm" + manual check steps.
- Device identifiers stay on the device; don't send them to any API.

## eSIM adapter (FR §P)
- Unprivileged only (EasyEUICC model). Never request or declare
  `WRITE_EMBEDDED_SUBSCRIPTIONS`, `MODIFY_PHONE_STATE`,
  `READ_PRIVILEGED_PHONE_STATE`, `SECURE_ELEMENT_PRIVILEGED_OPERATION`;
  never try to touch the phone's internal eSIM.
- Android only. iOS shows no adapter entry points at all.
- License boundary: link only lpac's LGPL `euicc/` library as its own `.so`.
  No AGPL lpac code (`src/`, `driver/`) in this repo, copied or adapted.
- Activation codes, matching IDs and confirmation codes are bearer secrets:
  never log them, never put them in analytics or crash reports, mask them in
  UI by default. The same goes for EIDs and ICCIDs read off the card.
- EID, ICCIDs and card info stay on the device. No Triptel endpoint takes
  them, so they are never sent anywhere.
- A download uses up the activation code. Always confirm first, and say so.
  Never auto-retry a download that reached the SM-DP+: a retry can fail as
  "already used," or worse.
- Delete is irreversible and disable switches off connectivity: both need
  explicit confirmation. Nothing in the app ever deletes or disables on its own.
- SGP.22 notifications are part of a correct operation: send them after
  download/enable/disable/delete, or queue them visibly. Never drop them
  silently.
- All USB I/O runs on one worker thread off the main thread. One card,
  one in-flight APDU exchange at a time.
- Protocol tests use real recorded transcripts or cited spec examples, never
  invented byte sequences presented as real.

## Design
- Use theme tokens and shared components only (`Design_System.md`). No raw hex in features.
- Follow Eskimo's patterns, never copy its assets, copy text, or brand colours.

## Process (harness)
- **Autonomous by default** (CLAUDE.md → Operating mode). No approval prompts, no
  check-ins: verify → commit → next feature. Blockers become `blocked` items, not pauses.
- **Commit and push every change without asking** (`git push origin main`), small
  and often. Public repo → no secrets or personal data, ever. Never force-push.
- **WIP = 1** in `feature_list.json`. Finish + verify before starting the next.
- A feature moves to `passing` only when its `verification` command passes, and
  that command was shown to **fail** with the feature reverted (this codebase has
  shipped vacuous tests at least three times).
- Don't "also fix" nearby things — add a `not_started` item instead.
- UI features also need on-device evidence: a screenshot path in `evidence`.
- Backend gaps are logged in `claude-progress.md` → "Blocked on backend", not
  worked around with fake data.
