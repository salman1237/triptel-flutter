#!/usr/bin/env bash
# One command to a working, verified environment. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")"

FLUTTER="${FLUTTER:-flutter}"
command -v "$FLUTTER" >/dev/null 2>&1 || FLUTTER="/c/Users/salman/flutter/bin/flutter"
ADB="${ADB:-adb}"
command -v "$ADB" >/dev/null 2>&1 || ADB="/c/Users/salman/AppData/Local/Android/Sdk/platform-tools/adb.exe"

echo "== Flutter"; "$FLUTTER" --version | head -1
echo "== pub get"; "$FLUTTER" pub get
echo "== Beta API health"
curl -fsS --max-time 10 https://beta.triptel.co/health && echo || echo "WARN: beta API not reachable"
echo "== Devices"; "$ADB" devices -l || true
echo "== Analyze"; "$FLUTTER" analyze
echo "== Tests"; "$FLUTTER" test
echo "init.sh: environment ready. Next: read claude-progress.md"
