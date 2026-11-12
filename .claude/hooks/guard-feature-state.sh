#!/usr/bin/env bash
# PreToolUse(Edit|Write): an agent may not flip a feature to "passing" by editing JSON
# unless verification has just been recorded as green in .harness/last-verify.
input="$(cat)"
printf '%s' "$input" | grep -q 'feature_list.json' || exit 0
printf '%s' "$input" | grep -Eq '\\?"passing\\?"' || exit 0
marker=".harness/last-verify"
if [ -f "$marker" ] && [ "$(find "$marker" -mmin -30 2>/dev/null)" ]; then
  exit 0
fi
echo "BLOCKED: setting a feature to \"passing\" without a fresh green verification." >&2
echo "WHY: only a passing verification command may move a feature to passing (docs/Rules.md)." >&2
echo "FIX: run the feature's verification command, then 'bash harness.sh verify' (it writes .harness/last-verify), then edit." >&2
exit 2
