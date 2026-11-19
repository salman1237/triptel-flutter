# Architecture
**Read when:** changing structure, adding a screen, or adding an API call.

## Stack
| Layer | Choice |
|---|---|
| Framework | Flutter 3.27.1 / Dart 3.6 (installed on this machine), Android + iOS |
| Navigation | `go_router` (StatefulShellRoute for the 4 tabs) |
| State | `flutter_riverpod` — providers per feature; `AsyncValue` for loading/error |
| HTTP | `dio` with one shared client (base URL, Bearer interceptor, error mapping) |
| Secure storage | `flutter_secure_storage` — JWT + `must_change_password` only |
| Prefs | `shared_preferences` — currency, language, pending purchase, cached settings |
| QR | `qr_flutter` (error correction H, embedded logo) |
| Gateway | `webview_flutter` (navigation interception, see API.md §9) |
| Links | `app_links` (`triptel://`), `url_launcher` (install links, mailto/tel/WhatsApp) |
| Share | `share_plus` |
| Google | `google_sign_in` v7 (`serverClientId` = web client id) |
| Files | `image_picker` (KYC, attachments) |
| Fonts | `google_fonts` (Plus Jakarta Sans) |
| Native | MethodChannel `co.triptel.app/esim` — Android `MainActivity.kt`, iOS `AppDelegate.swift` |
| eSIM adapter (§P, planned) | Kotlin USB CCID transport + lpac's `euicc/` (LGPL, NDK shared lib) behind channels `co.triptel.app/ccid/*` and `co.triptel.app/lpa` — Android only |

## Folder layout
```
lib/
  main.dart                    # ProviderScope + App
  app/                         # router.dart, app.dart, shell (bottom nav)
  core/
    config/                    # env (API_BASE_URL via --dart-define)
    network/                   # api_client.dart, api_exception.dart, interceptors
    storage/                   # secure_store.dart, prefs.dart
    money/                     # eur.dart (Decimal-ish), currency_format.dart, rates
    theme/                     # tokens.dart, theme.dart, typography.dart
    widgets/                   # shared components (Design_System.md §4)
  features/
    <feature>/
      data/                    # <feature>_api.dart (calls), models (fromJson)
      application/             # providers / notifiers (business rules)
      presentation/            # screens + feature widgets
test/                          # mirrors lib/
integration_test/              # on-device journeys
```
Features: `bootstrap, auth, catalog, checkout, esims, tracking, wallet,
withdrawals, referrals, compatibility, guides, account, kyc, support, legal,
support_chat, adapter` (`adapter` = FR §P, planned).

### eSIM adapter native layout (FR §P, planned)
```
lib/features/adapter/
  data/          ccid_channel.dart (EventChannel/MethodChannel), lpa_channel.dart
  application/   activation_code.dart (FR-L901, pure), lpa_error_messages.dart (pure),
                 providers (readers, chip info, profiles, notifications, download)
  presentation/  activation_input_screen.dart, adapter_screen.dart, download_screen.dart
android/app/src/main/kotlin/co/triptel/app/
  ccid/          UsbCcidReaders.kt (detect/hot-plug/permission), CcidTransceiver.kt,
                 Atr.kt, ApduChannel.kt (MANAGE CHANNEL, SELECT ISD-R, chaining)
  lpa/           LpaBridge.kt (JNI to euicc), HttpsDriver.kt
android/app/src/main/jni/   lpa-jni.mk + lpa_jni.c (APDU/HTTP driver glue, ndk-build
                             not CMake -- matches jmp-sim-manager's libs/lpac-jni,
                             DECISIONS.md 2026-11-19)
third_party/lpac-euicc/     vendored lpac euicc/ only, with its LICENSES (LGPL-2.1)
android/app/src/test/kotlin/  JVM unit tests (framing, ATR, APDU chaining transcripts)
```

## Layering rule
`presentation → application (providers) → data (api) → ApiClient → backend`.
A widget never imports `dio`; an API class never imports Flutter widgets. Business
rules (wallet-covers-price, plan-shape detection, compatibility verdict, poll
schedule, currency conversion) live in plain Dart so they are unit-testable.

## Key flows
### Checkout state machine (from web `PackageBrowser.tsx`)
```
compatCheck → review → [guest? save pending → login → resume]
  → choosePayment (wallet covers? sheet : gateway)
  → wallet:  POST /orders/checkout → poll
  → gateway: POST order-initiate(mobile:true) → WebView → triptel:// → poll
poll: 2s × ~6, then 5s until ~170s → success | preparing | error(FAILED only)
```
### Gateway WebView
Intercept `triptel://payment-callback`, `<FRONTEND>/wallet?topup=`,
`<FRONTEND>/my-esims/<id>?topup=`; external-launch `intent://`, `bkash://` etc.
After interception always re-read server state.

### Compatibility
`EsimSupportChannel` (data) returns raw signals → `evaluateEsimSupport()` (pure)
returns `EsimVerdict{supported|notSupported|unknown, deviceLabel, reason}` →
`esimVerdictProvider` (cached for the session) → used by compatibility screen,
checkout gate, install buttons, home promo.

### eSIM adapter (FR §P, planned)
```
Dart UI ─ providers ─ lpa_channel / ccid_channel  (platform channels; Android only)
   │                         │
   │                   LpaBridge.kt ── JNI ── lpac euicc/ (LGPL .so)
   │                                              │ APDU driver   │ HTTP driver
   │                                     ApduChannel.kt      HttpsDriver.kt ── SM-DP+ (ES9+)
   │                                              │
   │                                     CcidTransceiver.kt ── UsbDeviceConnection ── reader ── eUICC
   └─ activation_code.dart (pure)  ◄── QR / gallery / clipboard / manual / Triptel order data
```
One worker thread owns the USB connection and serialises every APDU (the
card is a single-threaded device). Long operations (download: tens of
seconds) report progress over an EventChannel; Dart never blocks on them.
A reader unplugged mid-operation surfaces as a typed error, never a crash.

### Money
API amounts are EUR strings → parse into an integer-cents/`Decimal` type at the
model boundary → convert for display only with `/settings/rates`. Never send a
converted amount back except where the endpoint takes `currency` explicitly
(wallet top-up, manual deposit).

## Environments
Only **beta** (`https://beta.triptel.co/api/v1`). Frontend host for redirect
matching: `https://beta.triptel.co` **and** `https://triptel.co`.
