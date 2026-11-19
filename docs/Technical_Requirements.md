# Technical Requirements
**Read when:** adding a dependency, or touching build / test / device setup.

## Toolchain on this machine (verified 2026-11-12)
| Tool | Version / path |
|---|---|
| Flutter | 3.27.1 stable (`C:\Users\salman\flutter\bin`) — Dart 3.6.0 |
| Android SDK | `C:/Users/salman/Android` (platform 35, build-tools 34) |
| adb | `C:\Users\salman\AppData\Local\Android\Sdk\platform-tools\adb.exe` |
| JDK | 23 (`C:\Program Files\Java\jdk-23`) → requires Gradle ≥ 8.10 |
| Gradle / AGP / Kotlin | 8.11.1 / 8.7.3 / 2.1.0 (bumped from the template's 8.3/8.1/1.8 for JDK 23) |
| Test device | vivo V2344, Android 14, serial `10EF1302BJ000R5` — **no eUICC** (`pm has-feature android.hardware.telephony.euicc` = false): perfect "not supported" case |
| iOS | Cannot build on Windows. iOS code is written to the same contract but unverified until a Mac/CI build |

| Android NDK / CMake | NDK `27.1.12297006`, CMake `3.22.1` and `3.31.6` under the SDK (verified 2026-11-19), needed only for FR §P (FR-L914) |
| Second test device | TMRV07P5G "Pinehurst", serial `BS88823AA14C0601334`, Android SDK 36 (used for FR-C901–C904 evidence). Verified 2026-11-19: `android.hardware.usb.host` = **true** (FR §P's USB-host phone), `android.hardware.telephony.euicc` = true (internal eSIM, irrelevant to §P) |

## Android config
`applicationId`/`namespace` `co.triptel.app`, `minSdk 23`, `compile/targetSdk 35`,
Java 17 target. `triptel://` intent filter. INTERNET permission.

## Dependencies (pubspec.yaml is the source of truth)
go_router · flutter_riverpod · dio · flutter_secure_storage · shared_preferences ·
qr_flutter · url_launcher · share_plus · webview_flutter · app_links ·
google_sign_in (v7 API: `GoogleSignIn.instance.initialize(serverClientId: ...)`) ·
image_picker · intl · google_fonts · cached_network_image · package_info_plus.
Dev: flutter_test · flutter_lints · mocktail · integration_test.
Adding a dependency: must support Dart 3.6, Android + iOS; record why in DECISIONS.md.
Also present: `web_socket_channel` (FR-C901), dev `flutter_launcher_icons`.

### Planned for FR §P (eSIM adapter), not added yet
| Piece | Plan | Constraint |
|---|---|---|
| `mobile_scanner` | FR-L902 QR camera + gallery-image decode | Pin the newest version that still supports Flutter 3.27 / Dart 3.6; record in DECISIONS.md |
| lpac `euicc/` | FR-L914, vendored C source under `third_party/lpac-euicc/`, built as its own `.so` via `externalNativeBuild` CMake | **LGPL-2.1-only** (or ESTKME commercial): keep it a separate shared library, ship its license + source notice, never statically merge it into app code. lpac's `src/` and `driver/` are **AGPL-3.0-only** — never vendored |
| ABIs | `arm64-v8a`, `armeabi-v7a`, `x86_64` | Pin `ndkVersion` in `android/app/build.gradle` |
| Android permissions | `android.hardware.usb.host` declared `required="false"`; `CAMERA` (FR-L902) | No `device_filter.xml` (no auto-launch on plug-in) |

### Hardware needed for FR §P (user-provided)
- A USB CCID smart-card reader (USB-C, or with an OTG adapter).
- A removable eUICC card that fits it (consumer "removable eSIM" class, e.g.
  9eSIM / eSTK.me). Its model goes into DECISIONS.md once known.
- A phone with USB host: `adb shell pm has-feature android.hardware.usb.host`
  (**the Pinehurst has it**, verified 2026-11-19).
- A free/test activation code for FR-L917 evidence (a real Triptel order's
  code is used up by a download, which is real money).

## Commands
| Command | Does |
|---|---|
| `bash harness.sh setup` / `./init.sh` | pub get, doctor summary, device check |
| `bash harness.sh run` | `flutter run -d 10EF1302BJ000R5 --dart-define=API_BASE_URL=https://beta.triptel.co/api/v1` |
| `bash harness.sh test` | `flutter test` |
| `bash harness.sh verify` | analyze (no issues) + format check + unit/widget tests + debug APK build |
| `bash harness.sh device-check` | install on the phone, launch, screenshot to `artifacts/` |
| `bash harness.sh shot x` | adb screenshot + UI dump into `artifacts/` |
| `bash harness.sh native-test` | Android JVM unit tests (`gradlew :app:testDebugUnitTest`) — FR §P's Kotlin framing/ATR/APDU logic. Verified 2026-11-19: builds and runs (`NO-SOURCE`, no Kotlin tests yet; ~5 min cold). The first Kotlin FR (FR-L912) adds `testImplementation` JUnit to `android/app/build.gradle` |

Override the device with `DEVICE=<serial> bash harness.sh ...` (default is the vivo).

## Verification layers (PDF "Don't let the agent grade itself")
1. Static: `flutter analyze`, `dart format --set-exit-if-changed`.
2. Runtime: unit + widget tests (`test/`), plus pure-logic tests for money,
   plan shapes, poll schedule, compatibility verdict, redirect parsing.
3. End-to-end: `integration_test/` journeys on the vivo device against beta, and
   adb screenshots checked by the reviewer agent.
4. FR §P (native): Kotlin JVM unit tests over **recorded byte transcripts**
   (CCID frames, ATRs, APDU exchanges) prove the protocol logic without
   hardware; Dart tests fake the platform channels; real-card evidence
   (EID read, profile list, download) is required before the FRs that
   touch the card can pass. A recorded transcript must come from a real
   reader/card session or a cited spec example, not be invented.

## MCP servers (`.mcp.json`)
| Server | Why | Note |
|---|---|---|
| `context7` (`@upstash/context7-mcp`) | Up-to-date docs for Flutter, go_router, Riverpod, dio, google_sign_in v7 | Add `CONTEXT7_API_KEY` env for higher limits (optional) |
| `mobile-mcp` (`@mobilenext/mobile-mcp`) | UI betterment loop: screenshots, element tree, taps on the real phone/emulator to review and polish screens | Needs adb on PATH |
| `dart` (`dart mcp-server`) | Official Dart/Flutter MCP: analyzer errors, widget tree, hot reload, runtime errors | **Requires Dart ≥ 3.9 (Flutter ≥ 3.35).** Installed is 3.6 → server won't start until `flutter upgrade` |

## Known setup gaps (user action)
- Google Sign-In: Android OAuth client for `co.triptel.app` + debug SHA-1 in the
  same Google Cloud project as the web client `1095507553767-…`.
- Flutter upgrade to ≥ 3.35 to enable the Dart MCP server (optional).
- Release keystore before any store build.
