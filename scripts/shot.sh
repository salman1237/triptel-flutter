#!/usr/bin/env bash
# Screenshot + compact UI dump of the phone's current screen into artifacts/.
# usage: scripts/shot.sh NAME
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
NAME="${1:-screen}"
ADB="${ADB:-/c/Users/salman/AppData/Local/Android/Sdk/platform-tools/adb.exe}"
DEVICE="${DEVICE:-10EF1302BJ000R5}"
mkdir -p artifacts
"$ADB" -s "$DEVICE" exec-out screencap -p > "artifacts/$NAME.png"
"$ADB" -s "$DEVICE" shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 || true
"$ADB" -s "$DEVICE" exec-out cat /sdcard/ui.xml > "artifacts/$NAME.xml" 2>/dev/null || true
echo "artifacts/$NAME.png"
