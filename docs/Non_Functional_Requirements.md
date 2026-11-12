# Non-Functional Requirements
**Read when:** a feature touches speed, safety, scale, offline or accessibility.
A feature is not `passing` until it clears the bars that apply to it.

## Performance
- Cold start to interactive Home ≤ 3 s on the vivo V2344 (debug excluded; profile build).
- Lists (countries 244, products 75+) scroll at 60 fps; use builders, no full rebuilds.
- Search debounce 300 ms; cancel in-flight requests on new input.
- Images: cached; flags at 80 px.

## Reliability
- No screen crashes on a 4xx/5xx/timeout: every async view has loading, error
  (with retry) and empty states.
- Network timeouts: connect 10 s, receive 30 s (checkout/top-up 45 s).
- Checkout poll survives app backgrounding: on resume, re-read the order.

## Offline
- Cached public settings + last My eSIMs list + last status snapshot (with
  "last updated" time) are shown offline. The QR/LPA must be viewable offline once
  loaded (a traveller may install on arrival without data).
- Mutations (pay, top-up, withdraw, ticket) require network; show a clear message.

## Security & privacy
- JWT only in secure storage; logs never contain tokens, LPA strings, ICCIDs, NID numbers.
- HTTPS only; no cleartext traffic.
- Device compatibility data never leaves the device.
- KYC images are uploaded and not kept in app storage afterwards.
- Screens showing QR/LPA may opt out of screenshots on Android only if the user asks (not default — users legitimately screenshot QRs).

## Accessibility
- Text contrast ≥ 4.5:1 (WCAG AA); large text ≥ 3:1.
- Tap targets ≥ 48 × 48 dp; semantics labels on icon-only buttons.
- Supports system font scale up to 1.3 without clipping key flows.

## i18n
- All user-visible strings via the translation layer (keys shared with web where they exist).
- RTL layout correct for Arabic (directional padding/alignment).
- Currency formatting per currency (JPY 0 decimals).

## Compatibility
- Android 6.0+ (API 23); eSIM detection meaningful on API 28+.
- iOS 13+ (detection uses 16+ API when available).
- Phone portrait first; layouts hold from 360 dp to 430 dp width.
