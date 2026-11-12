---
name: verify-on-device
description: End-to-end check of a Triptel feature on the connected Android phone against the beta API, producing screenshot evidence. Use before marking any UI or device feature passing.
---
# Verify on device

1. `adb devices -l` must list `10EF1302BJ000R5` as `device` (if `unauthorized`, ask
   the user to tap Allow on the phone).
2. `bash harness.sh device-check` (build, install, launch, `artifacts/launch.png`).
3. Drive to the feature: `adb shell input tap X Y` using bounds from
   `artifacts/<name>.xml`, or the `mobile-mcp` server tools.
4. `bash harness.sh shot <FR-id>` at each meaningful state; read the PNGs and check against
   the FR and `docs/design-reference/`.
5. For flows that spend money (checkout, top-up), use a beta test account only and
   the smallest product. Never confirm a real ShurjoPay payment without the user.
6. This phone has **no eUICC**: it validates the "not supported" path. The
   "supported" path needs an eSIM phone or a unit test with faked channel data —
   say which one was used in `evidence`.
7. Record screenshot paths + commit in `feature_list.json` → `evidence`.
