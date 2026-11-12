#!/usr/bin/env bash
# Canonical task runner (this machine has no `make`). usage: bash harness.sh <setup|run|test|verify|build|device-check|shot NAME>
set -euo pipefail
cd "$(dirname "$0")"
FLUTTER="${FLUTTER:-/c/Users/salman/flutter/bin/flutter}"
command -v flutter >/dev/null 2>&1 && FLUTTER="${FLUTTER_OVERRIDE:-flutter}"
ADB="${ADB:-/c/Users/salman/AppData/Local/Android/Sdk/platform-tools/adb.exe}"
DEVICE="${DEVICE:-10EF1302BJ000R5}"
API="${API_BASE_URL:-https://beta.triptel.co/api/v1}"
DEFINES="--dart-define=API_BASE_URL=$API"

case "${1:-}" in
  setup)  bash init.sh ;;
  run)    "$FLUTTER" run -d "$DEVICE" $DEFINES ;;
  test)   shift; "$FLUTTER" test "$@" ;;
  verify)
    "$FLUTTER" analyze
    dart format --output=none --set-exit-if-changed lib test
    "$FLUTTER" test
    "$FLUTTER" build apk --debug $DEFINES
    mkdir -p .harness && date > .harness/last-verify
    echo "VERIFY: green" ;;
  build)  "$FLUTTER" build apk --debug $DEFINES ;;
  device-check)
    "$FLUTTER" build apk --debug $DEFINES
    "$ADB" -s "$DEVICE" install -r build/app/outputs/flutter-apk/app-debug.apk
    "$ADB" -s "$DEVICE" shell monkey -p co.triptel.app -c android.intent.category.LAUNCHER 1 >/dev/null
    sleep 5
    bash scripts/shot.sh launch ;;
  shot)   bash scripts/shot.sh "${2:-screen}" ;;
  *) echo "usage: bash harness.sh <setup|run|test [path]|verify|build|device-check|shot NAME>"; exit 1 ;;
esac
