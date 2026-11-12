---
name: next-feature
description: Run the autonomous build loop for the Triptel Flutter app - pick the next feature from feature_list.json, implement, verify, review, commit, log, and continue to the next without asking. Use at the start of every session or whenever told to "continue", "next" or "build the app".
---
# Next feature (autonomous loop)

No approvals needed (the user granted all permissions). Repeat until no
`not_started`/`active` items remain:

1. `git status`; read `claude-progress.md`.
2. Pick the `active` item or the first `not_started`; set it `active` in
   `feature_list.json` (WIP = 1).
3. Read its FR in `docs/Functional_Requirements.md`, the endpoints in `docs/API.md`,
   `docs/Rules.md`, and the matching `docs/design-reference/` screenshot.
4. Implement using `new-screen` / `new-api-call`. Tests first for pure logic.
5. Run its `verification` command and `bash harness.sh verify`. Temporarily break the key line,
   confirm a test fails, restore. For ui/device items run `verify-on-device`.
6. Run the `reviewer` agent; fix FAILs until PASS.
7. `mkdir -p .harness && date > .harness/last-verify`, then set `state: "passing"`
   with `evidence: {"commit": "<hash>", "screens": [...], "notes": "..."}`.
8. Commit `feat(<area>): <FR-id> <short behavior>` and `git push origin main`; then
   commit + push the state update. No asking, ever. No secrets/personal data (public repo).
9. Append to `claude-progress.md`; update "Next step"; commit + push.
10. If blocked by something only the user/backend can supply: implement what's
    possible, set `state: "blocked"` + `blocked_reason`, log it, go to step 2.
11. Go to step 1 immediately.
