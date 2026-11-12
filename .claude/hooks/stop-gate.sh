#!/usr/bin/env bash
# Stop: clean-exit checklist reminder when code changed but state files didn't.
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
changed="$(git status --porcelain 2>/dev/null)"
[ -z "$changed" ] && exit 0
if printf '%s' "$changed" | grep -Eq ' (lib|test|android|ios)/' && ! printf '%s' "$changed" | grep -q 'claude-progress.md'; then
  echo '{"systemMessage":"Clean exit: code changed but claude-progress.md was not updated. Run bash harness.sh verify, update feature_list.json evidence + claude-progress.md, commit and push verified work (no need to ask)."}'
fi
exit 0
