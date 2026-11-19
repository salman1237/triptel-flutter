# OpenEUICC / EasyEUICC — Feature Reference

**Source:** https://github.com/estkme-group/openeuicc — explored read-only (cloned
to a scratchpad, no changes made, no commits/PRs/issues — respected the repo's
`CONTRIBUTING.md` LLM policy). Not a dependency of this app; this is a reference
document for scoping a possible future "write a profile to a removable eSIM /
USB adapter" feature here. Not yet an FR — nothing in `feature_list.json` depends
on this until the user picks specific items from it.

**Critical context:** OpenEUICC is two apps built from one codebase, and the
difference decides what's even possible for a Flutter app like this one.

| | **OpenEUICC** (privileged) | **EasyEUICC** (unprivileged) |
|---|---|---|
| Install | Must be a system/priv-app, signed/preinstalled by OEM | Installable like any normal app |
| Internal eSIM | Yes | No |
| Removable/external eSIM | Yes | Only if the chip's own allowlist permits it |
| USB CCID reader | Yes | Yes |
| Permissions | `WRITE_EMBEDDED_SUBSCRIPTIONS`, `MODIFY_PHONE_STATE`, `READ_PRIVILEGED_PHONE_STATE`, `SECURE_ELEMENT_PRIVILEGED_OPERATION` — all signature/privileged, unobtainable by a sideloaded/Play Store app | None of the above — confirmed, its manifest has zero special permissions |

**This Flutter app can only ever be an "EasyEUICC," never an "OpenEUICC."**
Managing a phone's internal eSIM is a dead end — Google will never grant that
permission to a normal app, regardless of signing or ARA-M. Everything below is
scoped with that in mind.

---

## 1. eUICC/chip detection & connection

### 1.1 Internal eSIM access (OMAPI)
`OmapiApduInterface.kt`. Talks to the chip through Android's `android.se.omapi`
system service (`SEService` → `Session` → `Channel`), the OS-standard Secure
Element access API. Works because OpenEUICC is a privileged app.
**Not portable** — platform-privileged only, not available to this app.

### 1.2 Removable/external eSIM access
Same `OmapiApduInterface` path, but for an external SE in the SIM tray. Works
for a normal app **only if** the chip's own ARA-M (Access Rule Application
Master) access-control list grants that app's signing certificate hash
permission. The README states the ARA-M hash OpenEUICC/EasyEUICC checks for is
`2A2FA878BC7C3354C2CF82935A5945A3EDAE4AFA` — the chip vendor has to allowlist
the app specifically; you can't detect-and-write any removable eSIM chip from a
normal app. **Portable in principle** via Android's OMAPI Java API from a
native Android plugin — but gated entirely by the chip vendor's own rules, not
something this app controls.

### 1.3 USB CCID smart-card reader — the real "adapter card" feature
`core/usb/UsbCcidContext.kt`, `UsbCcidTransceiver.kt`, `UsbCcidDescription.kt`,
`UsbCcidUtils.kt`, `UsbApduInterface.kt`. Fully portable, no special Android
permission needed beyond normal USB host access. How it actually works:

- **Detection**: enumerates `UsbManager.deviceList` and checks each device's
  USB interfaces for `interfaceClass == UsbConstants.USB_CLASS_CSCID` (0x0B,
  the standard "Chip/SmartCard" USB class) — generic, works for any
  CCID-compliant reader, not a vendor allowlist.
- **Live hot-plug**: `MainActivity` registers a runtime `BroadcastReceiver` for
  `UsbManager.ACTION_USB_DEVICE_ATTACHED`/`ACTION_USB_DEVICE_DETACHED` while
  the app is foregrounded, and re-scans on each event. No manifest
  `device_filter.xml` — it doesn't auto-launch on plug-in, only detects while
  the app is open.
- **Permission**: standard Android USB host flow —
  `usbManager.requestPermission(device, pendingIntent)`, user taps "Allow,"
  result delivered via a broadcast with a custom action string.
- **Low-level protocol**: implements the real USB-CCID spec (DWG Smart-Card
  USB ICC Devices rev 1.0) by hand — `PC_to_RDR_IccPowerOn`,
  `PC_to_RDR_XfrBlock`, `PC_to_RDR_SetParameters`, bulk-transfer framing with
  sequence numbers, ATR (Answer-To-Reset) parsing per ISO/IEC 7816-3, T=0/T=1
  protocol negotiation, voltage selection (5V/3V/1.8V, falls back on
  power-select errors), a hardcoded quirk table for readers needing TPDU mode
  (e.g. Realtek RTS5169).
- **APDU layer on top**: `UsbApduInterface` opens/closes SGP.22 logical
  channels (`MANAGE CHANNEL`), selects the ISD-R applet by AID, sends Terminal
  Capabilities, handles APDU response chaining (SW=0x61 "more data available"
  → `GET RESPONSE`, SW=0x6C "wrong Le" → retry with corrected length).

**Not portable to pure Dart.** USB bulk-transfer I/O and this entire protocol
stack need a native Android plugin (Kotlin + `UsbManager`/`UsbDeviceConnection`,
exposed to Flutter via a MethodChannel/EventChannel, or Dart FFI if the raw
transceiver logic is ported to C). The protocol logic itself is conceptually
portable (it's a state machine over USB bulk transfers) — reimplement it or
wrap this exact code as a native Android plugin, don't expect to reuse Kotlin
directly from Dart.

### 1.4 Chip abstraction layer
`EuiccChannel.kt`/`EuiccChannelImpl.kt`/`DefaultEuiccChannelManager.kt`. A
unifying interface so the rest of the app doesn't care whether it's talking to
internal SE, external SE, or USB — each exposes `logicalSlotId`, `portId`, a
`SecureElementId`, and the same `LocalProfileAssistant` (see §3). Worth
copying the architectural pattern even when reimplementing the transports.

---

## 2. Profile download ("writing a profile")

Driven by `lpac` (the open-source LPA core library this project wraps via JNI
— `libs/lpac-jni`), exposed through `LocalProfileAssistant.downloadProfile(input, callback)`.

### 2.1 Input shape (`ProfileDownloadInput`)
```
address: String           // SM-DP+ server hostname
matchingId: String?       // "activation code" / matching ID from the QR
imei: String?             // device IMEI, sometimes required by the carrier
confirmationCode: String? // optional PIN some profiles require
```

### 2.2 Four ways to get there (`DownloadWizardMethodSelectFragment`)
- **QR camera scan** — via a zxing-based barcode scanner
  (`journeyapps/zxing-android-embedded`'s `ScanContract`), QR format only.
- **QR from a gallery image** — pick an image, decode with `BitmapFactory` +
  zxing's bitmap decoder.
- **Paste from clipboard** — reads `ClipboardManager`'s primary clip text.
- **Manual entry** — a form for SM-DP+ address / matching ID / confirmation
  code directly.

All four funnel into the same LPA string parser (`util/LPAString.kt`), which
implements SGP.22's activation code format exactly:
`LPA:1$<smdp-address>$<matching-id>$<oid>$<confirmation-code-required-flag>`,
dollar-sign-delimited, also handles the string arriving wrapped inside a URL
query parameter (the `lpa:` deep link case). **Trivial, fully portable** —
~20 lines, straightforward to reimplement in Dart.

### 2.3 The actual download
`lpac`'s `downloadProfile()` runs the real SGP.22 **ES9+** remote-provisioning
handshake against the SM-DP+ server over HTTPS (initiate authentication → get
bound profile package → install), streaming the encrypted profile package down
to the chip via APDU commands over whichever channel (OMAPI or USB) is active.
Progress comes back through `ProfileDownloadCallback.onStatusUpdate(state): Boolean`
— a `ProfileDownloadState` enum drives the wizard's progress UI
(`DownloadWizardProgressFragment`). **Not portable** — the deepest,
standards-heaviest part (TLS, CBOR/ASN.1 per SGP.22, cryptographic
profile-package handling). Use `lpac`'s own C library (standalone open-source,
not Android-specific) via a native plugin/FFI rather than reimplementing it.

### 2.4 `lpa:` deep link
`DeepLinkConfirmationActivity.kt`, documented in `docs/DEEP-LINK.md` of that
repo. Other apps can launch
`Intent(ACTION_VIEW, Uri.parse("lpa:1$rsp.example.com$matching-id"))` to hand
off straight into the download flow, skipping the QR step. **Directly
relevant to Triptel**: the backend could drive an "Install now" button
straight into this scheme on a device that has an LPA app registered for it.

### 2.5 Wizard flow
`ui/wizard/`: slot select → method select → details/confirm →
low-power-mode warning (NFC/cellular radio interference) → progress →
diagnostics-on-failure. `SimplifiedErrorMessages.kt` maps raw `lpac`/SGP.22
error codes to user-friendly text — worth copying the *mapping-table concept*
even without reusing the code.

---

## 3. Profile management

All via `lpac`'s `LocalProfileAssistant` interface
(`LocalProfileAssistantWrapper.kt` is the thin wrapper OpenEUICC adds):
- `profiles: List<LocalProfileInfo>` — list all profiles on the chip (ICCID,
  nickname, provider name, enabled state, etc.)
- `enableProfile(iccid, refresh: Boolean)` /
  `disableProfile(iccid, refresh: Boolean)` — switch the active profile
  (SGP.22 only allows one enabled profile at a time on most chips); `refresh`
  controls whether the modem radio restarts immediately.
- `deleteProfile(iccid)` — permanently erase a profile from the chip.
- `setNickname(iccid, nickname)` — purely local display-name metadata
  (`ProfileRenameFragment.kt`), not sent to the carrier.
- `eID` — the chip's own unique EID (needed for linking a chip to an order —
  an operator needs it to generate a matching profile).
- `euiccInfo2` — chip capability/firmware info (`EuiccInfoActivity.kt`).
- `euiccMemoryReset()` — factory-reset the eUICC
  (`EuiccMemoryResetFragment.kt`), destructive, test-profile cleanup use case.

**Portability**: the operations themselves are simple once `lpac` is wired up
(native plugin/FFI) — not separately complex beyond that one integration.

---

## 4. Notifications (SGP.22-mandated)

`NotificationsActivity.kt` + `LocalProfileNotification`. SGP.22 requires the
LPA to send "I installed/enabled/disabled/deleted this profile" notifications
back to the SM-DP+/SM-DS — this is how a carrier confirms a profile was
actually provisioned, and some carrier-side anti-abuse logic depends on it.
`lpac` queues these as pending `notifications: List<LocalProfileNotification>`;
the app lets the user manually `handleNotification(seqNumber)` (send it) or
`deleteNotification(seqNumber)` (discard — e.g. if the network's unreachable
and the user wants to clear the backlog). **Needed for correctness** if this
app ever writes a real profile — skipping it silently breaks the spec-mandated
handshake with the carrier, even though nothing visibly fails immediately.

---

## 5. Multi-chip / multi-slot support

`DefaultEuiccChannelManager` tracks multiple simultaneous channels — internal
SE(s), one external/removable SE, one USB reader — and `MainActivity` renders
each as a separate tab (`EuiccManagementFragment` per channel).
`IsdrAidListActivity.kt` handles chips exposing multiple ISD-R applets
(multi-eUICC-profile chips). Relevant only if this app ever needs to switch
between, say, an internal test chip and a USB reader in the same session —
likely overkill for a travel-eSIM marketplace app focused on "write one
profile to one reader."

---

## 6. UI/UX & settings (lower priority, still useful patterns)
- `SettingsActivity`/`SettingsFragment` + `ui/preference/`: verbose logging
  toggle, force-TPDU-mode override (manual reader-quirk workaround),
  notification auto-send toggle.
- `LogsActivity.kt`: on-device diagnostic log viewer — a good pattern for a
  future support/debug screen when a profile write fails.
- `BaseEuiccAccessActivity`/`NoEuiccPlaceholderFragment`: graceful "no eUICC
  found" states.
- System integration: registers as a handler for Android's built-in
  `EUICC_UI` category (`BIND_EUICC_SERVICE`) so it can appear as the system's
  SIM-management UI — privileged-only, not relevant here.

---

## Bottom line

Realistically buildable here, as a "write a profile to an external/removable
eSIM or a USB CCID reader" feature (the EasyEUICC model):

1. **A native Android plugin** for USB CCID detection + the byte-level
   transceiver protocol (§1.3) — the real engineering work, no Flutter-native
   equivalent exists; needs raw `UsbManager`/`UsbDeviceConnection` access.
2. Either bundle **`lpac`** itself (standalone, liberally-licensed C library,
   not tied to the Android app) via FFI/native plugin for the actual SGP.22
   ES9+ handshake + APDU profile-install sequence, or fork the relevant
   `lpac-jni` bindings specifically.
3. **QR scanning + the `LPAString` parser** (§2.1–2.2) — trivial, fully
   reimplementable in pure Dart with any QR package (e.g. `mobile_scanner`).
4. **Profile list/enable/disable/delete/nickname** (§3) and **notification
   handling** (§4) — thin wrappers once `lpac` is wired up.
5. **Internal eSIM management** (§1.1) and the system-level `EUICC_UI`
   integration — not achievable in this app, skip entirely.

**Not yet scoped as an FR.** Revisit this doc and turn the wanted subset into
`feature_list.json` items once a decision is made on which pieces to build.
