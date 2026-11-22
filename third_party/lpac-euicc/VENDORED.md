# Vendored: lpac's `euicc/` + its build-time dependencies

FR-L914 (`docs/Functional_Requirements.md` section P2). License path
confirmed by the user 2026-11-22 (`DECISIONS.md`): **LGPL-2.1-only**,
not the ESTKME commercial license.

## What's here, and why

- `euicc/` -- the actual SGP.22 LPA core. Vendored **unmodified**,
  wholesale (all `.c`/`.h` files), from:
  https://github.com/estkme-group/lpac
  commit `654215e44b22dbbd1377932b2fa4c76d308cc5ab` (2026-11-08).
  Per that repo's own `REUSE.toml`: `euicc/**` is
  `LGPL-2.1-only OR LicenseRef-ESTKME-Commercial` -- **only** this
  directory is vendored here. `src/`, `driver/`, `utils/`, `tests/`
  (AGPL-3.0-only) are never copied into this repo, built, or linked
  against, per `docs/Rules.md`.
- `cjson-ext/` -- lpac's own small cJSON extension (`cJSON_ex.c/h`),
  MIT-licensed per the same `REUSE.toml`, from the same commit. Needed
  because `euicc/es9p.c` includes it (build-time dependency of the
  vendored `euicc/` sources, even though this app's current scope --
  reader detection, APDU, EID read -- never calls the ES9+/HTTP code
  paths that actually use it).
- `cjson/` -- upstream cJSON itself (`cJSON.c/h` only, not
  `cJSON_Utils`), MIT-licensed, from:
  https://github.com/DaveGamble/cJSON
  commit `6d9f2443ab071f86e5d9b43025a40929ec41c46c` (2026-09-16).
  `cjson-ext/cJSON_ex.h` includes `cJSON.h`.
- `LICENSES/` -- the two license texts that actually apply here
  (`LGPL-2.1-only.txt`, `MIT.txt`), copied from lpac's own `LICENSES/`
  directory (also `euicc/LICENSE` keeps the LGPL text directly
  alongside the code it covers, matching upstream's own layout) and
  `cjson/LICENSE` (cJSON's own MIT text).

## Build-file provenance (ndk-build, not CMake)

The vendored CMake build files (lpac upstream's own `euicc/CMakeLists.txt`)
are **not used** -- this app builds `euicc/*.c` + `cjson-ext/*.c` +
`cjson/cJSON.c` via `ndk-build` (`android/app/src/main/jni/`), matching
a real, independently-verified reference implementation
(`gitea.angry.im/jmp-sim/jmp-sim-manager`'s `libs/lpac-jni/src/main/jni/lpac-jni.mk`,
researched and cited in `DECISIONS.md` 2026-11-19) rather than guessing
the build-tooling shape.

## This app's own code (not vendored, written here)

`android/app/src/main/jni/lpa_jni.c` -- the JNI glue implementing
`struct euicc_apdu_interface` (from `euicc/interface.h`) by calling
back up into the already-built, already-device-verified Kotlin
`CcidTransceiver`/`ApduChannel` (FR-L912/FR-L913), not duplicating any
USB/APDU logic in C. This file, and the `android/app/src/main/jni/*.mk`
build files, are Triptel's own code, not vendored.

## Revisit if

- lpac publishes a security fix to `euicc/` -- re-vendor from a newer
  commit, re-run the full FR-L912/913/914 on-device verification
  (vendored code, not configuration, so nothing here is auto-updated).
- A future distribution channel needs different LGPL compliance
  artifacts (e.g. publishing modified `euicc/` sources on request) --
  this vendoring already satisfies "ship the exact unmodified upstream
  source," which is the simplest compliant position.
