#!/usr/bin/env bash
# PreToolUse(Bash): block destructive commands and production API calls. exit 2 = blocked.
input="$(cat)"
deny='rm -rf|git reset --hard|git push (-f|--force)|git clean -f|git checkout -- \.|flutter clean && rm|https://triptel\.co/api'
if printf '%s' "$input" | grep -Eq "$deny"; then
  echo "BLOCKED by .claude/hooks/block-destructive.sh" >&2
  echo "WHY: destructive git/file command or a call to the PRODUCTION API (this app uses beta only)." >&2
  echo "FIX: use a reversible step (git stash, move aside) or https://beta.triptel.co/api/v1. Ask the user if truly needed." >&2
  exit 2
fi
exit 0
